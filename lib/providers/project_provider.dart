import 'package:flutter/material.dart';
import '../models/project_session.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';

enum ProjectConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class ProjectProvider extends ChangeNotifier {
  ProjectConnectionStatus _status = ProjectConnectionStatus.disconnected;
  ProjectSession? _session;
  String? _errorMessage;
  String? _fileName;
  String? _serviceAccountRaw;
  bool _isBackendOnline = false;
  String? _backendVersion;

  ProjectConnectionStatus get status => _status;
  ProjectSession? get session => _session;
  bool get isConnected => _status == ProjectConnectionStatus.connected && _session != null;
  bool get isConnecting => _status == ProjectConnectionStatus.connecting;
  String? get errorMessage => _errorMessage;
  String? get fileName => _fileName;
  String? get serviceAccountRaw => _serviceAccountRaw;
  bool get isBackendOnline => _isBackendOnline;
  String? get backendVersion => _backendVersion;

  ProjectProvider() {
    _init();
  }

  Future<void> _init() async {
    await checkBackendHealth();
    // Check if we had an existing session saved
    final saved = StorageService.getSavedSession();
    if (saved != null) {
      _session = saved;
      _status = ProjectConnectionStatus.connected;
      notifyListeners();
    }
  }

  Future<bool> checkBackendHealth() async {
    final res = await ApiService.checkHealth();
    if (res.success && res.data != null) {
      _isBackendOnline = true;
      _backendVersion = res.data!['version']?.toString() ?? '1.0.0';
    } else {
      _isBackendOnline = false;
    }
    notifyListeners();
    return _isBackendOnline;
  }

  /// Connect using a service account JSON string
  Future<bool> connectWithJson(String rawJson, {String? fileName}) async {
    _errorMessage = null;
    _status = ProjectConnectionStatus.connecting;
    notifyListeners();

    // 1. Client-side validation for instant user feedback
    final validation = AppValidators.validateServiceAccount(rawJson);
    if (!validation.isValid) {
      _status = ProjectConnectionStatus.error;
      _errorMessage = validation.errorMessage;
      notifyListeners();
      return false;
    }

    _serviceAccountRaw = rawJson;
    _fileName = fileName ?? 'service-account.json';

    // 2. Submit to backend API to initialize Firebase Admin SDK in memory
    final apiRes = await ApiService.connectProject(validation.data);
    if (apiRes.success && apiRes.data != null) {
      _session = apiRes.data;
      _status = ProjectConnectionStatus.connected;
      _errorMessage = null;
      await StorageService.saveSession(_session!);
      _isBackendOnline = true;
      notifyListeners();
      return true;
    } else {
      _status = ProjectConnectionStatus.error;
      _errorMessage = apiRes.errorMessage ?? 'Failed to connect service account to Firebase.';
      notifyListeners();
      return false;
    }
  }

  /// Disconnect current project and clear session
  Future<void> disconnect() async {
    if (_session != null) {
      try {
        await ApiService.disconnectProject(_session!.sessionId);
      } catch (e) {
        // Ignore network failure on disconnect
      }
    }
    _session = null;
    _serviceAccountRaw = null;
    _fileName = null;
    _status = ProjectConnectionStatus.disconnected;
    _errorMessage = null;
    await StorageService.clearSession();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == ProjectConnectionStatus.error) {
      _status = _session != null ? ProjectConnectionStatus.connected : ProjectConnectionStatus.disconnected;
    }
    notifyListeners();
  }
}
