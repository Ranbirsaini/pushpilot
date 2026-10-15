class TokenDeliveryResult {
  final String token;
  final bool success;
  final String? messageId;
  final FcmErrorDetail? error;

  TokenDeliveryResult({
    required this.token,
    required this.success,
    this.messageId,
    this.error,
  });

  factory TokenDeliveryResult.fromJson(Map<String, dynamic> json) {
    return TokenDeliveryResult(
      token: json['token']?.toString() ?? '',
      success: json['success'] == true,
      messageId: json['messageId']?.toString(),
      error: json['error'] != null ? FcmErrorDetail.fromJson(json['error']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'success': success,
      'messageId': messageId,
      'error': error?.toJson(),
    };
  }
}

class FcmErrorDetail {
  final String code;
  final String message;
  final String? action;

  FcmErrorDetail({
    required this.code,
    required this.message,
    this.action,
  });

  factory FcmErrorDetail.fromJson(Map<String, dynamic> json) {
    return FcmErrorDetail(
      code: json['code']?.toString() ?? 'unknown_error',
      message: json['message']?.toString() ?? '',
      action: json['action']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'action': action,
    };
  }
}

class SendResult {
  final bool success;
  final int totalTokens;
  final int successCount;
  final int failureCount;
  final String? projectId;
  final String? note;
  final List<TokenDeliveryResult> results;

  SendResult({
    required this.success,
    required this.totalTokens,
    required this.successCount,
    required this.failureCount,
    this.projectId,
    this.note,
    this.results = const [],
  });

  factory SendResult.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List<dynamic>? ?? [];
    return SendResult(
      success: json['success'] == true,
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      successCount: (json['successCount'] as num?)?.toInt() ?? 0,
      failureCount: (json['failureCount'] as num?)?.toInt() ?? 0,
      projectId: json['projectId']?.toString(),
      note: json['note']?.toString(),
      results: list.map((e) => TokenDeliveryResult.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
