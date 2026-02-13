import 'package:cloud_firestore/cloud_firestore.dart';

class FeedEntity {
  final String id;
  final String url;
  final String content;
  final DateTime timestamp;
  final String? userId;
  final List<String> likedBy;
  final String status;
  final DateTime? releaseTime;

  FeedEntity({
    required this.id,
    required this.url,
    required this.content,
    required this.timestamp,
    this.userId,
    this.likedBy = const [],
    this.status = 'RELEASED',
    this.releaseTime,
  });

  factory FeedEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final String url =
        data['imageUrl'] as String? ?? data['url'] as String? ?? '';
    final String content =
        data['caption'] as String? ?? data['content'] as String? ?? '';
    final DateTime timestamp = (data['createdAt'] as Timestamp?)?.toDate() ??
        (data['timestamp'] as Timestamp?)?.toDate() ??
        DateTime.now();
    final String? userId =
        data['authorId'] as String? ?? data['userId'] as String?;
    final String status = data['status'] as String? ?? 'RELEASED';
    final DateTime? releaseTime = (data['releaseTime'] as Timestamp?)?.toDate();

    return FeedEntity(
      id: doc.id,
      url: url,
      content: content,
      timestamp: timestamp,
      userId: userId,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      status: status,
      releaseTime: releaseTime,
    );
  }

  bool isLiked(String currentUserId) {
    return likedBy.contains(currentUserId);
  }
}
