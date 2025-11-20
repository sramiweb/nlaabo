class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
    this.metadata,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError('Notification ID cannot be empty');
    }
    if (userId.trim().isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('Notification title cannot be empty');
    }
    if (message.trim().isEmpty) {
      throw ArgumentError('Notification message cannot be empty');
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    final id = json['id'];
    if (id == null || id.toString().trim().isEmpty) {
      throw const FormatException('Notification ID is required and cannot be empty');
    }

    final userId = json['user_id'];
    if (userId == null || userId.toString().trim().isEmpty) {
      throw const FormatException('User ID is required and cannot be empty');
    }

    final title = json['title'];
    if (title == null || title.toString().trim().isEmpty) {
      throw const FormatException(
        'Notification title is required and cannot be empty',
      );
    }

    final message = json['message'];
    if (message == null || message.toString().trim().isEmpty) {
      throw const FormatException(
        'Notification message is required and cannot be empty',
      );
    }

    // Parse and validate createdAt
    DateTime createdAt;
    try {
      final createdAtStr = json['created_at'];
      if (createdAtStr != null && createdAtStr.toString().isNotEmpty) {
        createdAt = DateTime.parse(createdAtStr.toString());
      } else {
        throw const FormatException('Created date is required');
      }
    } catch (e) {
      throw FormatException('Invalid created_at format: $e');
    }

    final type = json['type']?.toString() ?? 'system_notification';

    return NotificationModel(
      id: id.toString(),
      userId: userId.toString(),
      title: title.toString(),
      message: message.toString(),
      type: type,
      relatedId: json['related_id']?.toString(),
      isRead: json['is_read'] == true,
      createdAt: createdAt,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'related_id': relatedId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
