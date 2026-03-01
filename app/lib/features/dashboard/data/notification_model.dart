class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String message;
  final String? payloadJson;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    this.payloadJson,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      message: json['message'],
      payloadJson: json['payload_json'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'message': message,
      'payload_json': payloadJson,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
