import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { like, comment, filmDeveloped, system }

class NotificationEntity {
  NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.postId,
  });

  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? postId;

  factory NotificationEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};

    final rawType = (data['type'] as String? ?? '').toLowerCase();
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return NotificationEntity(
      id: doc.id,
      title: data['title'] as String? ?? 'Notification',
      message: data['message'] as String? ?? '',
      type: _typeFromRaw(rawType),
      createdAt: createdAt,
      isRead: data['isRead'] as bool? ?? false,
      postId: data['postId'] as String?,
    );
  }

  static NotificationType _typeFromRaw(String value) {
    switch (value) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'film_developed':
      case 'filmdeveloped':
      case 'developed':
        return NotificationType.filmDeveloped;
      default:
        return NotificationType.system;
    }
  }
}
