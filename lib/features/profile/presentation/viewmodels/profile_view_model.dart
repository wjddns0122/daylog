import 'dart:async';

import 'package:daylog/features/feed/domain/entities/feed_entity.dart';
import 'package:daylog/features/feed/domain/repositories/feed_repository.dart';
import 'package:daylog/features/feed/presentation/providers/feed_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileState {
  final List<FeedEntity> posts;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    List<FeedEntity>? posts,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfileViewModel extends StateNotifier<ProfileState> {
  final FeedRepository _feedRepository;
  final String userId;
  StreamSubscription<List<FeedEntity>>? _subscription;

  ProfileViewModel(this._feedRepository, this.userId)
      : super(const ProfileState(isLoading: true)) {
    _subscribeToUserPosts();
  }

  void _subscribeToUserPosts() {
    _subscription?.cancel();

    _subscription = _feedRepository.getMyFeedStream(userId).listen((posts) {
      // Filter by RELEASED status
      final releasedPosts =
          posts.where((post) => post.status == 'RELEASED').toList();

      // Sort by newest first (descending timestamp)
      releasedPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (mounted) {
        state = state.copyWith(
          posts: releasedPosts,
          isLoading: false,
          error: null,
        );
      }
    }, onError: (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final profileViewModelProvider = StateNotifierProvider.autoDispose
    .family<ProfileViewModel, ProfileState, String>((ref, userId) {
  final feedRepository = ref.watch(feedRepositoryProvider);
  return ProfileViewModel(feedRepository, userId);
});
