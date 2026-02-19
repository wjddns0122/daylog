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
    this.payload,
  });

  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? postId;
  final Map<String, dynamic>? payload;

  String? get relatedPostId {
    final directId = postId?.trim();
    if (directId != null && directId.isNotEmpty) {
      return directId;
    }

    final payloadData = payload;
    if (payloadData == null) {
      return null;
    }

    final dynamic candidate = payloadData['postId'] ??
        payloadData['relatedPostId'] ??
        payloadData['targetPostId'];

    if (candidate is String && candidate.trim().isNotEmpty) {
      return candidate.trim();
    }

    return null;
  }

  factory NotificationEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};

    final rawType = (data['type'] as String? ?? '').toLowerCase();
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final payload = _parsePayload(data['payload']);

    return NotificationEntity(
      id: doc.id,
      title: data['title'] as String? ?? 'Notification',
      message: data['message'] as String? ?? '',
      type: _typeFromRaw(rawType),
      createdAt: createdAt,
      isRead: data['isRead'] as bool? ?? false,
      postId: data['postId'] as String?,
      payload: payload,
    );
  }

  static Map<String, dynamic>? _parsePayload(dynamic rawPayload) {
    if (rawPayload is Map<String, dynamic>) {
      return rawPayload;
    }

    if (rawPayload is Map) {
      return rawPayload.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return null;
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
