class ProjectSession {
  final String sessionId;
  final String projectId;
  final String clientEmail;
  final String connectedAt;

  ProjectSession({
    required this.sessionId,
    required this.projectId,
    required this.clientEmail,
    required this.connectedAt,
  });

  factory ProjectSession.fromJson(Map<String, dynamic> json) {
    return ProjectSession(
      sessionId: json['sessionId']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      clientEmail: json['clientEmail']?.toString() ?? '',
      connectedAt: json['connectedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'projectId': projectId,
      'clientEmail': clientEmail,
      'connectedAt': connectedAt,
    };
  }
}
