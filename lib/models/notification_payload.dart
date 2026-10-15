class NotificationPayload {
  final List<String> tokens;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final String priority;

  NotificationPayload({
    required this.tokens,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data = const {},
    this.priority = 'high',
  });

  Map<String, dynamic> toJson({String? sessionId, dynamic serviceAccount}) {
    final map = <String, dynamic>{
      'tokens': tokens,
      'title': title,
      'body': body,
      'priority': priority,
      'data': data,
    };
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      map['imageUrl'] = imageUrl!.trim();
    }
    if (sessionId != null) {
      map['sessionId'] = sessionId;
    }
    if (serviceAccount != null) {
      map['serviceAccount'] = serviceAccount;
    }
    return map;
  }
}
