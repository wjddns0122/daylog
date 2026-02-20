import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../../../feed/domain/entities/feed_entity.dart';
import '../../../feed/domain/repositories/feed_repository.dart';

class LikeNotifier extends StreamNotifier<List<FeedEntity>> {
  late FeedRepository _repository;

  @override
  Stream<List<FeedEntity>> build() {
    _repository = ref.watch(feedRepositoryProvider);

    // Wait for auth to be ready before querying
    final userIdAsync = ref.watch(currentUserIdProvider);
    final userId = userIdAsync.valueOrNull;

    if (userIdAsync.isLoading || userId == null) {
      return Stream.value([]);
    }

    return _repository.getLikedFeedStream(userId);
  }

  Future<void> toggleLike(String postId, List<String> likedBy) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isLiked = likedBy.contains(user.uid);
    await _repository.toggleLike(postId, user.uid, isLiked);
  }
}

final likeProvider = StreamNotifierProvider<LikeNotifier, List<FeedEntity>>(
  LikeNotifier.new,
);
