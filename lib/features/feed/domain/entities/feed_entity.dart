import 'package:cloud_firestore/cloud_firestore.dart';

class FeedEntity {
  final String id;
  final String url;
  final String content;
  final DateTime timestamp;
  final String? userId;
  final List<String> likedBy;
  final String status;
  final String visibility;
  final DateTime? releaseTime;
  final String? aiCuration;
  final String? musicTitle;
  final String? musicUrl;

  FeedEntity({
    required this.id,
    required this.url,
    required this.content,
    required this.timestamp,
    this.userId,
    this.likedBy = const [],
    this.status = 'RELEASED',
    this.visibility = 'PRIVATE',
    this.releaseTime,
    this.aiCuration,
    this.musicTitle,
    this.musicUrl,
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
    final String visibility = data['visibility'] as String? ?? 'PRIVATE';
    final DateTime? releaseTime = (data['releaseTime'] as Timestamp?)?.toDate();
    // Cloud Functions stores AI data in nested 'ai' map
    final Map<String, dynamic>? aiData = data['ai'] as Map<String, dynamic>?;

    final String? aiCuration = aiData?['curation'] as String? ??
        data['curation'] as String? ??
        data['aiCuration'] as String? ??
        data['aiCurationText'] as String? ??
        data['curationText'] as String? ??
        data['poeticText'] as String?;
    final String? musicTitle = aiData?['youtubeTitle'] as String? ??
        data['musicTitle'] as String? ??
        data['bgmTitle'] as String?;
    final String? musicUrl = aiData?['youtubeUrl'] as String? ??
        data['youtubeUrl'] as String? ??
        data['musicUrl'] as String? ??
        data['bgmUrl'] as String?;

    return FeedEntity(
      id: doc.id,
      url: url,
      content: content,
      timestamp: timestamp,
      userId: userId,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      status: status,
      visibility: visibility,
      releaseTime: releaseTime,
      aiCuration: aiCuration,
      musicTitle: musicTitle,
      musicUrl: musicUrl,
    );
  }

  bool isLiked(String currentUserId) {
    return likedBy.contains(currentUserId);
  }
}
