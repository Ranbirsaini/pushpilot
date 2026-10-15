import 'package:intl/intl.dart';

class AppFormatters {
  /// Mask device FCM token for privacy
  /// e.g. fQ91zk...981724
  static String maskToken(String? token) {
    if (token == null || token.trim().isEmpty) return 'No token';
    final trimmed = token.trim();
    if (trimmed.length <= 12) return '******';
    return '${trimmed.substring(0, 6)}...${trimmed.substring(trimmed.length - 6)}';
  }

  /// Format ISO 8601 string or DateTime into readable date/time
  static String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      DateTime dt;
      if (timestamp is DateTime) {
        dt = timestamp;
      } else {
        dt = DateTime.parse(timestamp.toString()).toLocal();
      }
      return DateFormat('MMM dd, yyyy • hh:mm:ss a').format(dt);
    } catch (e) {
      return timestamp.toString();
    }
  }

  /// Short relative-like or compact time
  static String formatShortTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      DateTime dt;
      if (timestamp is DateTime) {
        dt = timestamp;
      } else {
        dt = DateTime.parse(timestamp.toString()).toLocal();
      }
      return DateFormat('HH:mm:ss').format(dt);
    } catch (e) {
      return '';
    }
  }

  /// Format integer numbers with commas
  static String formatNumber(int value) {
    return NumberFormat('#,###').format(value);
  }
}
