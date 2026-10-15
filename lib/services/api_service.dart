import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_payload.dart';
import '../models/project_session.dart';
import '../models/send_result.dart';
import '../models/notification_history_item.dart';
import 'storage_service.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? errorMessage;

  ApiResponse({
    required this.success,
    this.data,
    this.errorMessage,
  });
}

class ApiService {
  static String get baseUrl => StorageService.getApiBaseUrl();

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Check if the backend is reachable
  static Future<ApiResponse<Map<String, dynamic>>> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri, headers: _headers).timeout(
            const Duration(seconds: 5),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(success: true, data: data);
      } else {
        return ApiResponse(
          success: false,
          errorMessage: 'Server returned HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        errorMessage:
            'Cannot connect to PushPilot backend at $baseUrl. Ensure the backend server is running ("npm start" in backend/). Error: $e',
      );
    }
  }

  /// Connect and initialize Firebase Project with Service Account JSON
  static Future<ApiResponse<ProjectSession>> connectProject(dynamic serviceAccountJson) async {
    try {
      final uri = Uri.parse('$baseUrl/project/connect');
      final body = jsonEncode({
        'serviceAccount': serviceAccountJson,
      });

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final session = ProjectSession.fromJson(data['session']);
        return ApiResponse(success: true, data: session);
      } else {
        return ApiResponse(
          success: false,
          errorMessage: data['error']?.toString() ?? 'Failed to connect Firebase project.',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        errorMessage: 'Connection error: $e. Verify backend is running at $baseUrl',
      );
    }
  }

  /// Disconnect active session
  static Future<ApiResponse<bool>> disconnectProject(String sessionId) async {
    try {
      final uri = Uri.parse('$baseUrl/project/disconnect');
      final body = jsonEncode({'sessionId': sessionId});

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);
      return ApiResponse(success: true, data: data['disconnected'] == true);
    } catch (e) {
      return ApiResponse(success: false, errorMessage: e.toString());
    }
  }

  /// Send FCM Notification
  static Future<ApiResponse<SendResult>> sendNotification({
    required NotificationPayload payload,
    String? sessionId,
    dynamic serviceAccount,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/notifications/send');
      final body = jsonEncode(payload.toJson(
        sessionId: sessionId,
        serviceAccount: serviceAccount,
      ));

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 25));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final result = SendResult.fromJson(data);
        return ApiResponse(success: true, data: result);
      } else {
        return ApiResponse(
          success: false,
          errorMessage: data['error']?.toString() ?? 'Notification send request failed.',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        errorMessage: 'Failed to send notification: $e. Check server status.',
      );
    }
  }

  /// Send quick test notification to a device token
  static Future<ApiResponse<SendResult>> sendTestNotification({
    required String token,
    String? sessionId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/notifications/test');
      final body = jsonEncode({
        'token': token,
        'sessionId': sessionId,
      });

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final result = SendResult.fromJson(data);
        return ApiResponse(success: true, data: result);
      } else {
        return ApiResponse(
          success: false,
          errorMessage: data['error']?.toString() ?? 'Test notification failed.',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        errorMessage: 'Network error: $e',
      );
    }
  }

  /// Fetch history from backend
  static Future<ApiResponse<List<NotificationHistoryItem>>> fetchHistory({String? projectId}) async {
    try {
      String url = '$baseUrl/notifications/history';
      if (projectId != null && projectId.isNotEmpty) {
        url += '?projectId=$projectId';
      }
      final uri = Uri.parse(url);
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['history'] as List<dynamic>? ?? [])
            .map((e) => NotificationHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: list);
      } else {
        return ApiResponse(success: false, errorMessage: 'Failed to fetch history');
      }
    } catch (e) {
      return ApiResponse(success: false, errorMessage: e.toString());
    }
  }

  /// Fetch stats
  static Future<ApiResponse<Map<String, dynamic>>> fetchStats({String? projectId}) async {
    try {
      String url = '$baseUrl/stats';
      if (projectId != null && projectId.isNotEmpty) {
        url += '?projectId=$projectId';
      }
      final uri = Uri.parse(url);
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(success: true, data: data['stats'] as Map<String, dynamic>);
      }
      return ApiResponse(success: false, errorMessage: 'Failed to fetch stats');
    } catch (e) {
      return ApiResponse(success: false, errorMessage: e.toString());
    }
  }
}
