import 'package:daylog/core/theme/app_theme.dart';
import 'package:daylog/features/feed/domain/entities/feed_entity.dart';
import 'package:daylog/features/feed/presentation/widgets/feed_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// A full-screen feed detail view that shows a tapped post first,
/// followed by the remaining posts in a scrollable list.
class FeedDetailScreen extends ConsumerWidget {
  const FeedDetailScreen({
    super.key,
    required this.posts,
    required this.initialPostId,
  });

  final List<FeedEntity> posts;
  final String initialPostId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordered = _reorderByInitialPost(posts, initialPostId);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Image.asset(
          'assets/images/logo_header.png',
          height: 30,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 120),
        itemCount: ordered.length,
        itemBuilder: (context, index) {
          return FeedCard(item: ordered[index]);
        },
      ),
    );
  }

  List<FeedEntity> _reorderByInitialPost(
    List<FeedEntity> posts,
    String selectedPostId,
  ) {
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
