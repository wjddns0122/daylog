import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../../../feed/domain/entities/feed_entity.dart';
import '../../../feed/domain/repositories/feed_repository.dart';

// Reuse feedRepository from feed feature or create new one?
// We can import feedRepositoryProvider from feed feature.

class LikeNotifier extends StreamNotifier<List<FeedEntity>> {
  late final FeedRepository _repository;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Stream<List<FeedEntity>> build() {
    _repository = ref.watch(feedRepositoryProvider);
    if (_userId == null) {
      return Stream.value([]);
    }
    return _repository.getLikedFeedStream(_userId);
  }

  Future<void> toggleLike(String postId, List<String> likedBy) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isLiked = likedBy.contains(user.uid);
    // Optimistic update can be complicated with Stream, but since we rely on Firestore stream,
    // we just call the repo method and let the stream update.
    // However, for immediate UI feedback, we might want to do something, but Stream is usually fast enough.
    await _repository.toggleLike(postId, user.uid, isLiked);
  }
}

final likeProvider = StreamNotifierProvider<LikeNotifier, List<FeedEntity>>(
  LikeNotifier.new,
);
