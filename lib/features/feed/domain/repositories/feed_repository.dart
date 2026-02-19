import '../entities/feed_entity.dart';
import '../entities/comment_entity.dart';

abstract class FeedRepository {
  Stream<List<FeedEntity>> getFeedStream();
  Stream<List<FeedEntity>> getMyFeedStream(String userId);
  Stream<List<FeedEntity>> getLikedFeedStream(String userId);
  Stream<FeedEntity?> getLatestPostForUser(String userId);
  Future<List<FeedEntity>> getUserPostsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get pending post for the current user
  Stream<FeedEntity?> getMyPendingPost(String userId);

  Future<FeedEntity?> getPostById(String postId);

  Future<void> deletePost(String postId, String imageUrl);
  Future<void> toggleLike(String postId, String userId, bool isLiked);
  Future<void> updatePostCaption(String postId, String newCaption);

  // Comments
  Stream<List<CommentEntity>> getComments(String postId);
  Future<void> addComment(String postId, String userId, String text);
  Future<void> deleteComment(String postId, String commentId);
}
