import '../entities/feed_entity.dart';

abstract class FeedRepository {
  Stream<List<FeedEntity>> getFeedStream();
  Future<void> deletePost(String postId, String imageUrl);
  Future<void> toggleLike(String postId, String userId, bool isLiked);
}
