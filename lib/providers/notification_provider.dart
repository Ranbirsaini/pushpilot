import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/notification_payload.dart';
import '../models/send_result.dart';
import '../models/notification_history_item.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';
import 'project_provider.dart';

class NotificationProvider extends ChangeNotifier {
  // Composer Form controllers
  final TextEditingController tokensController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();

  // Custom data pairs (Key - Value)
  final Map<String, String> _customData = {};
  String _rawJsonData = '{\n  "screen": "product_details",\n  "productId": "123",\n  "type": "offer"\n}';
  bool _isRawJsonMode = false;
  String? _jsonValidationError;

  // Options
  String _priority = 'high';
  String _previewPlatform = 'android'; // 'android' | 'ios'

  // Sending state
  bool _isSending = false;
  SendResult? _lastSendResult;
  String? _sendError;

  // History & Statistics
  List<NotificationHistoryItem> _history = [];
  bool _isLoadingHistory = false;

  // Getters
  Map<String, String> get customData => Map.unmodifiable(_customData);
  String get rawJsonData => _rawJsonData;
  bool get isRawJsonMode => _isRawJsonMode;
  String? get jsonValidationError => _jsonValidationError;
  String get priority => _priority;
  String get previewPlatform => _previewPlatform;
  bool get isSending => _isSending;
  SendResult? get lastSendResult => _lastSendResult;
  String? get sendError => _sendError;
  List<NotificationHistoryItem> get history => List.unmodifiable(_history);
  bool get isLoadingHistory => _isLoadingHistory;

  // Parsed tokens list
  List<String> get parsedTokens => AppValidators.parseTokens(tokensController.text);
  int get tokenCount => parsedTokens.length;

  // Stats getters
  int get totalRequests => _history.length;
  int get totalTokensSent => _history.fold(0, (sum, item) => sum + item.tokensCount);
  int get successfulDeliveries => _history.fold(0, (sum, item) => sum + item.successCount);
  int get failedDeliveries => _history.fold(0, (sum, item) => sum + item.failureCount);
  double get successRate {
    if (totalTokensSent == 0) return 100.0;
    return (successfulDeliveries / totalTokensSent) * 100.0;
  }

  NotificationProvider() {
    _init();
    tokensController.addListener(notifyListeners);
    titleController.addListener(notifyListeners);
    bodyController.addListener(notifyListeners);
    imageUrlController.addListener(notifyListeners);
  }

  void _init() {
    // Load local history
    _history = StorageService.getLocalHistory();
    // Default sample data pair
    _customData['screen'] = 'product_details';
    _customData['productId'] = '123';
    _customData['type'] = 'offer';
    _syncCustomDataToRawJson();
    notifyListeners();
  }

  void setPreviewPlatform(String platform) {
    _previewPlatform = platform;
    notifyListeners();
  }

  void setPriority(String p) {
    _priority = p;
    notifyListeners();
  }

  void toggleJsonMode(bool raw) {
    if (raw) {
      _syncCustomDataToRawJson();
    } else {
      _syncRawJsonToCustomData();
    }
    _isRawJsonMode = raw;
    notifyListeners();
  }

  void updateRawJson(String raw) {
    _rawJsonData = raw;
    final val = AppValidators.validateJson(raw);
    if (!val.isValid) {
      _jsonValidationError = val.errorMessage;
    } else if (val.data is! Map) {
      _jsonValidationError = 'JSON root must be an object (e.g. {"key": "value"})';
    } else {
      _jsonValidationError = null;
      _syncRawJsonToCustomData();
    }
    notifyListeners();
  }

  void addCustomDataPair(String key, String value) {
    final k = key.trim();
    if (k.isNotEmpty) {
      _customData[k] = value.trim();
      _syncCustomDataToRawJson();
      notifyListeners();
    }
  }

  void removeCustomDataPair(String key) {
    _customData.remove(key);
    _syncCustomDataToRawJson();
    notifyListeners();
  }

  void _syncCustomDataToRawJson() {
    const encoder = JsonEncoder.withIndent('  ');
    _rawJsonData = encoder.convert(_customData);
    _jsonValidationError = null;
  }

  void _syncRawJsonToCustomData() {
    try {
      final decoded = jsonDecode(_rawJsonData);
      if (decoded is Map) {
        _customData.clear();
        decoded.forEach((key, value) {
          _customData[key.toString()] = value?.toString() ?? '';
        });
        _jsonValidationError = null;
      }
    } catch (e) {
      // Keep previous data
    }
  }

  /// Populate sample test notification fields for easy 1-click testing
  void loadSamplePayload({String? sampleToken}) {
    if (sampleToken != null && sampleToken.isNotEmpty) {
      tokensController.text = sampleToken;
    } else if (tokensController.text.trim().isEmpty) {
      tokensController.text =
          'fQ91zklA9482710492817409182374981723984712093847109283740981724\n'
          'c7F819401827391028371928371928371928371928371928371928371928371';
    }

    titleController.text = '🎉 Flash Sale: 50% Off Everything!';
    bodyController.text = 'Don\'t miss out on our biggest weekend discount yet. Tap here to browse exclusive deals!';
    imageUrlController.text = 'https://picsum.photos/seed/pushpilot/600/300';

    _customData.clear();
    _customData['screen'] = 'flash_sale_view';
    _customData['discountCode'] = 'FLASH50';
    _customData['category'] = 'electronics';
    _syncCustomDataToRawJson();
    notifyListeners();
  }

  /// Clear the notification composer form
  void clearForm() {
    tokensController.clear();
    titleController.clear();
    bodyController.clear();
    imageUrlController.clear();
    _customData.clear();
    _rawJsonData = '{\n}';
    _jsonValidationError = null;
    _lastSendResult = null;
    _sendError = null;
    notifyListeners();
  }

  /// Send FCM Notification
  Future<bool> sendNotification(ProjectProvider projectProvider) async {
    final tokens = parsedTokens;
    if (tokens.isEmpty) {
      _sendError = 'Please enter at least one valid FCM device token.';
      notifyListeners();
      return false;
    }

    if (titleController.text.trim().isEmpty) {
      _sendError = 'Notification title cannot be empty.';
      notifyListeners();
      return false;
    }

    if (bodyController.text.trim().isEmpty) {
      _sendError = 'Notification message body cannot be empty.';
      notifyListeners();
      return false;
    }

    if (_jsonValidationError != null) {
      _sendError = 'Please fix custom data JSON errors before sending.';
      notifyListeners();
      return false;
    }

    _isSending = true;
    _sendError = null;
    _lastSendResult = null;
    notifyListeners();

    // Prepare custom data map
    final Map<String, dynamic> finalData = {};
    _customData.forEach((k, v) {
      finalData[k] = v;
    });

    final payload = NotificationPayload(
      tokens: tokens,
      title: titleController.text.trim(),
      body: bodyController.text.trim(),
      imageUrl: imageUrlController.text.trim().isNotEmpty ? imageUrlController.text.trim() : null,
      data: finalData,
      priority: _priority,
    );

    final res = await ApiService.sendNotification(
      payload: payload,
      sessionId: projectProvider.session?.sessionId,
      serviceAccount: projectProvider.serviceAccountRaw,
    );

    _isSending = false;

    if (res.success && res.data != null) {
      _lastSendResult = res.data;
      _sendError = null;

      // Add to local history list
      final newHistoryItem = NotificationHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now().toIso8601String(),
        projectId: projectProvider.session?.projectId ?? 'Local Project',
        title: payload.title,
        body: payload.body,
        imageUrl: payload.imageUrl,
        tokensCount: tokens.length,
        sampleToken: tokens.first,
        successCount: _lastSendResult!.successCount,
        failureCount: _lastSendResult!.failureCount,
        status: _lastSendResult!.failureCount == 0
            ? 'SUCCESS'
            : _lastSendResult!.successCount == 0
                ? 'FAILED'
                : 'PARTIAL',
        results: _lastSendResult!.results,
        data: finalData,
      );

      _history.insert(0, newHistoryItem);
      await StorageService.saveLocalHistory(_history);
      notifyListeners();
      return true;
    } else {
      _sendError = res.errorMessage ?? 'Failed to send notification.';
      notifyListeners();
      return false;
    }
  }

  /// Send quick test notification
  Future<bool> sendQuickTest({
    required String token,
    required ProjectProvider projectProvider,
  }) async {
    _isSending = true;
    _sendError = null;
    notifyListeners();

    final res = await ApiService.sendTestNotification(
      token: token.trim(),
      sessionId: projectProvider.session?.sessionId,
    );

    _isSending = false;

    if (res.success && res.data != null) {
      _lastSendResult = res.data;
      _sendError = null;

      final testItem = NotificationHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now().toIso8601String(),
        projectId: projectProvider.session?.projectId ?? 'PushPilot Test',
        title: '🚀 PushPilot Test Notification',
        body: 'FCM test message dispatched successfully!',
        tokensCount: 1,
        sampleToken: token.trim(),
        successCount: _lastSendResult!.successCount,
        failureCount: _lastSendResult!.failureCount,
        status: _lastSendResult!.failureCount == 0 ? 'SUCCESS' : 'FAILED',
        results: _lastSendResult!.results,
        data: {'type': 'test_ping'},
      );

      _history.insert(0, testItem);
      await StorageService.saveLocalHistory(_history);
      notifyListeners();
      return true;
    } else {
      _sendError = res.errorMessage ?? 'Test notification failed.';
      notifyListeners();
      return false;
    }
  }

  /// Clear all history records
  Future<void> clearHistory() async {
    _history.clear();
    await StorageService.clearHistory();
    notifyListeners();
  }

  /// Sync history from backend if available
  Future<void> syncHistoryFromBackend({String? projectId}) async {
    _isLoadingHistory = true;
    notifyListeners();

    final res = await ApiService.fetchHistory(projectId: projectId);
    _isLoadingHistory = false;

    if (res.success && res.data != null && res.data!.isNotEmpty) {
      // Merge unique by id or timestamp
      final existingIds = _history.map((e) => e.id).toSet();
      for (final item in res.data!) {
        if (!existingIds.contains(item.id)) {
          _history.add(item);
        }
      }
      _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await StorageService.saveLocalHistory(_history);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    tokensController.dispose();
    titleController.dispose();
    bodyController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }
}
