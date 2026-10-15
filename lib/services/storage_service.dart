import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_history_item.dart';
import '../models/project_session.dart';
import '../utils/constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // API Base URL
  static String getApiBaseUrl() {
    return _prefs?.getString(AppConstants.keyApiUrl) ?? AppConstants.defaultApiBaseUrl;
  }

  static Future<void> setApiBaseUrl(String url) async {
    await _prefs?.setString(AppConstants.keyApiUrl, url.trim());
  }

  // Theme Mode
  static String getThemeMode() {
    return _prefs?.getString(AppConstants.keyThemeMode) ?? 'dark';
  }

  static Future<void> setThemeMode(String mode) async {
    await _prefs?.setString(AppConstants.keyThemeMode, mode);
  }

  // Project Session
  static ProjectSession? getSavedSession() {
    final raw = _prefs?.getString(AppConstants.keySessionInfo);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      return ProjectSession.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveSession(ProjectSession session) async {
    await _prefs?.setString(AppConstants.keySessionInfo, jsonEncode(session.toJson()));
  }

  static Future<void> clearSession() async {
    await _prefs?.remove(AppConstants.keySessionInfo);
  }

  // Notification History
  static List<NotificationHistoryItem> getLocalHistory() {
    final raw = _prefs?.getString(AppConstants.keyHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => NotificationHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveLocalHistory(List<NotificationHistoryItem> items) async {
    try {
      final list = items.take(100).map((e) => e.toJson()).toList();
      await _prefs?.setString(AppConstants.keyHistory, jsonEncode(list));
    } catch (e) {
      // Ignore
    }
  }

  static Future<void> clearHistory() async {
    await _prefs?.remove(AppConstants.keyHistory);
  }
}
