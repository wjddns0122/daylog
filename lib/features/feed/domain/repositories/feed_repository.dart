import '../entities/feed_entity.dart';

abstract class FeedRepository {
  Stream<List<FeedEntity>> getFeedStream();
  Stream<List<FeedEntity>> getLikedFeedStream(String userId);

  /// Get pending post for the current user
  Stream<FeedEntity?> getMyPendingPost(String userId);

  Future<void> deletePost(String postId, String imageUrl);
  Future<void> toggleLike(String postId, String userId, bool isLiked);
}
