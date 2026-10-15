import 'send_result.dart';

class NotificationHistoryItem {
  final String id;
  final String timestamp;
  final String projectId;
  final String title;
  final String body;
  final String? imageUrl;
  final int tokensCount;
  final String sampleToken;
  final int successCount;
  final int failureCount;
  final String status; // 'SUCCESS' | 'FAILED' | 'PARTIAL'
  final List<TokenDeliveryResult> results;
  final Map<String, dynamic> data;

  NotificationHistoryItem({
    required this.id,
    required this.timestamp,
    required this.projectId,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.tokensCount,
    required this.sampleToken,
    required this.successCount,
    required this.failureCount,
    required this.status,
    this.results = const [],
    this.data = const {},
  });

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) {
    final resultsList = json['results'] as List<dynamic>? ?? [];
    return NotificationHistoryItem(
      id: json['id']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      projectId: json['projectId']?.toString() ?? 'N/A',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      tokensCount: (json['tokensCount'] as num?)?.toInt() ?? 1,
      sampleToken: json['sampleToken']?.toString() ?? '***',
      successCount: (json['successCount'] as num?)?.toInt() ?? 0,
      failureCount: (json['failureCount'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'SUCCESS',
      results: resultsList.map((e) => TokenDeliveryResult.fromJson(e as Map<String, dynamic>)).toList(),
      data: json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'projectId': projectId,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'tokensCount': tokensCount,
      'sampleToken': sampleToken,
      'successCount': successCount,
      'failureCount': failureCount,
      'status': status,
      'results': results.map((r) => r.toJson()).toList(),
      'data': data,
    };
  }
}
