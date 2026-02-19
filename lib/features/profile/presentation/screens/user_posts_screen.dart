import 'package:daylog/core/theme/app_theme.dart';
import 'package:daylog/features/feed/domain/entities/feed_entity.dart';
import 'package:daylog/features/feed/presentation/widgets/feed_card.dart';
import 'package:daylog/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserPostsScreen extends ConsumerWidget {
  const UserPostsScreen({
    super.key,
    required this.userId,
    this.initialPostId,
    this.title,
  });

  final String userId;
  final String? initialPostId;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileViewModelProvider(userId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        title: Text(title == null || title!.isEmpty ? '게시물' : '$title 게시물'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, profileState.posts),
    );
  }

  Widget _buildBody(BuildContext context, List<FeedEntity> posts) {
    if (posts.isEmpty) {
      return const Center(child: Text('아직 게시물이 없어요.'));
    }

    final sorted = [...posts]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final ordered = _reorderByInitialPost(sorted, initialPostId);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: ordered.length,
      itemBuilder: (context, index) {
        return FeedCard(item: ordered[index]);
      },
    );
  }

  List<FeedEntity> _reorderByInitialPost(
    List<FeedEntity> posts,
    String? selectedPostId,
  ) {
    if (selectedPostId == null || selectedPostId.isEmpty) {
      return posts;
    }

    final selectedIndex = posts.indexWhere((post) => post.id == selectedPostId);
    if (selectedIndex <= 0) {
      return posts;
    }

    final selected = posts[selectedIndex];
    final leading = posts.sublist(0, selectedIndex);
    final trailing = posts.sublist(selectedIndex + 1);
    return [selected, ...trailing, ...leading];
  }
}
