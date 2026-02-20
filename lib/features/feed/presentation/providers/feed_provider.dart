import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/entities/feed_entity.dart';
import '../../domain/repositories/feed_repository.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepositoryImpl();
});

/// Provides the current user's UID reactively, updating on auth state changes.
final currentUserIdProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((user) => user?.uid);
});

// Convert to StreamNotifier to handle methods like deletePost
class FeedNotifier extends StreamNotifier<List<FeedEntity>> {
  late FeedRepository _repository;

  @override
  Stream<List<FeedEntity>> build() {
    _repository = ref.watch(feedRepositoryProvider);

    // Wait for auth to be ready before querying
    final userIdAsync = ref.watch(currentUserIdProvider);
    final userId = userIdAsync.valueOrNull;

    // If auth is still loading or user is not logged in, return empty
    if (userIdAsync.isLoading || userId == null) {
      return Stream.value(const []);
    }

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
    }

    final isLiked = likedBy.contains(user.uid);
    await _repository.toggleLike(postId, user.uid, isLiked);
  }
}

final feedProvider = StreamNotifierProvider<FeedNotifier, List<FeedEntity>>(
  FeedNotifier.new,
);

final myDiaryFeedProvider = StreamProvider.autoDispose<List<FeedEntity>>((ref) {
  final userIdAsync = ref.watch(currentUserIdProvider);
  final userId = userIdAsync.valueOrNull;
  if (userId == null) {
    return Stream.value(const []);
  }

  final repository = ref.watch(feedRepositoryProvider);
  return repository.getMyFeedStream(userId);
});

final currentUserLatestPostProvider = StreamProvider.autoDispose<FeedEntity?>(
  (ref) {
    final userIdAsync = ref.watch(currentUserIdProvider);
    final userId = userIdAsync.valueOrNull;
    if (userId == null) {
      return Stream.value(null);
    }

    final repository = ref.watch(feedRepositoryProvider);
    return repository.getLatestPostForUser(userId);
  },
);

final currentPendingPostProvider =
    StreamProvider.autoDispose<FeedEntity?>((ref) {
  final userIdAsync = ref.watch(currentUserIdProvider);
  final userId = userIdAsync.valueOrNull;
  if (userId == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(feedRepositoryProvider);
  return repository.getMyPendingPost(userId);
});
