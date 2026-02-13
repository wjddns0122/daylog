import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/entities/feed_entity.dart';
import '../../domain/repositories/feed_repository.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepositoryImpl();
});

// Convert to StreamNotifier to handle methods like deletePost
class FeedNotifier extends StreamNotifier<List<FeedEntity>> {
  late final FeedRepository _repository;

  @override
  Stream<List<FeedEntity>> build() {
    _repository = ref.watch(feedRepositoryProvider);
    return _repository.getFeedStream();
  }

  Future<void> deletePost(String postId, String imageUrl) async {
    await _repository.deletePost(postId, imageUrl);
    // Stream will automatically update
  }

  Future<void> toggleLike(String postId, List<String> likedBy) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    } // Should allow sign in or show error, but silent for now

    final isLiked = likedBy.contains(user.uid);
    await _repository.toggleLike(postId, user.uid, isLiked);
  }
}

final feedProvider = StreamNotifierProvider<FeedNotifier, List<FeedEntity>>(
  FeedNotifier.new,
);

final currentPendingPostProvider =
    StreamProvider.autoDispose<FeedEntity?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(null);
  }
  final repository = ref.watch(feedRepositoryProvider);
  return repository.getMyPendingPost(user.uid);
});
