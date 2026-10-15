import 'dart:convert';

class ValidationResult<T> {
  final bool isValid;
  final String? errorMessage;
  final T? data;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.data,
  });
}

class AppValidators {
  /// Validates a raw JSON string for syntax and returns parsed object or error
  static ValidationResult<dynamic> validateJson(String raw) {
    if (raw.trim().isEmpty) {
      return ValidationResult(isValid: true, data: <String, dynamic>{});
    }
    try {
      final parsed = jsonDecode(raw);
      return ValidationResult(isValid: true, data: parsed);
    } on FormatException catch (e) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'JSON Syntax Error: ${e.message}',
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Invalid JSON: $e',
      );
    }
  }

  /// Validates Firebase Service Account JSON
  static ValidationResult<Map<String, dynamic>> validateServiceAccount(String content) {
    if (content.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'The file is empty. Please select a valid service account JSON.',
      );
    }

    dynamic parsed;
    try {
      parsed = jsonDecode(content);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Malformed JSON file. Ensure you uploaded an uncorrupted JSON file.',
      );
    }

    if (parsed is! Map<String, dynamic>) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Invalid JSON structure: Root must be a JSON object.',
      );
    }

    // Check for common error: Android google-services.json
    if (parsed.containsKey('project_info') ||
        parsed.containsKey('client') ||
        parsed.containsKey('configuration_version')) {
      return ValidationResult(
        isValid: false,
        errorMessage:
            'You uploaded an Android client "google-services.json" file!\n\n'
            'PushPilot requires a Firebase Service Account Private Key.\n'
            'How to get it:\n'
            '1. Go to Firebase Console -> Project Settings (⚙️)\n'
            '2. Select the "Service Accounts" tab\n'
            '3. Click "Generate new private key"\n'
            '4. Upload that downloaded JSON file here.',
      );
    }

    // Check for iOS plist converted to json
    if (parsed.containsKey('CLIENT_ID') || parsed.containsKey('REVERSED_CLIENT_ID')) {
      return ValidationResult(
        isValid: false,
        errorMessage:
            'You uploaded an iOS "GoogleService-Info.plist" file instead of a Firebase Service Account JSON.',
      );
    }

    // Required fields check
    final requiredKeys = ['project_id', 'private_key', 'client_email'];
    final missing = requiredKeys.where((k) => !parsed.containsKey(k) || parsed[k] == null).toList();

    if (missing.isNotEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Missing required field(s): ${missing.join(', ')}. Please verify your service account key.',
      );
    }

    final privateKey = parsed['private_key'].toString();
    if (!privateKey.contains('BEGIN PRIVATE KEY')) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Invalid "private_key" format. The key must contain "-----BEGIN PRIVATE KEY-----".',
      );
    }

    return ValidationResult(isValid: true, data: parsed);
  }

  /// Parses multi-token text input (one per line, or comma separated)
  static List<String> parseTokens(String raw) {
    if (raw.trim().isEmpty) return [];

    final split = raw.split(RegExp(r'[\n\r,]+'));
    return split
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet() // deduplicate
        .toList();
  }

  /// Validate single FCM token basic sanity
  static String? validateSingleToken(String? token) {
    if (token == null || token.trim().isEmpty) {
      return 'FCM device token cannot be empty.';
    }
    final trimmed = token.trim();
    if (trimmed.length < 20) {
      return 'Token appears too short (FCM tokens are usually 100+ characters).';
    }
    if (trimmed.contains(' ')) {
      return 'Token contains spaces. Please check for accidental spaces.';
    }
    return null;
  }
}
