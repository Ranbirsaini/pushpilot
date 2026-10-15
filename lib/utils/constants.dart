import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'PushPilot';
  static const String appTagline = 'Firebase FCM Push Notification Management';
  static const String appVersion = '1.0.0';

  // Default API endpoint - automatically adapts to live website origin on Web
  static String get defaultApiBaseUrl {
    try {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && !origin.startsWith('file://')) {
        // If testing on Flutter local debug port (not 5050), use backend port 5050
        if (origin.contains('localhost') && !origin.contains(':5050')) {
          return 'http://localhost:5050/api';
        }
        return '$origin/api';
      }
    } catch (_) {}
    return 'http://localhost:5050/api';
  }

  // Storage keys
  static const String keyApiUrl = 'pushpilot_api_url';
  static const String keyThemeMode = 'pushpilot_theme_mode';
  static const String keyHistory = 'pushpilot_history_v1';
  static const String keySessionInfo = 'pushpilot_session_info';

  // Color Palette
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color accent = Color(0xFFEC4899); // Pink

  // Status Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color successBg = Color(0x1A10B981);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningBg = Color(0x1AF59E0B);
  static const Color error = Color(0xFFEF4444); // Red
  static const Color errorBg = Color(0x1AEF4444);
  static const Color info = Color(0xFF3B82F6); // Blue
  static const Color infoBg = Color(0x1A3B82F6);

  // Dark Theme Neutral Colors
  static const Color darkBg = Color(0xFF0B0F19);
  static const Color darkCard = Color(0xFF151D2F);
  static const Color darkCardHover = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF26334D);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Light Theme Neutral Colors
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
}
