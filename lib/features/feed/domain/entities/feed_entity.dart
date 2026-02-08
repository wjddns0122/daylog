import 'package:cloud_firestore/cloud_firestore.dart';

class FeedEntity {
  final String id;
  final String url;
  final String content;
  final DateTime timestamp;
  final String? userId;
  final List<String> likedBy;

  FeedEntity({
    required this.id,
    required this.url,
    required this.content,
    required this.timestamp,
    this.userId,
    this.likedBy = const [],
  });

  factory FeedEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedEntity(
      id: doc.id,
      url: data['url'] as String,
      content: data['content'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['userId'] as String?,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  bool isLiked(String currentUserId) {
    return likedBy.contains(currentUserId);
  }
}
