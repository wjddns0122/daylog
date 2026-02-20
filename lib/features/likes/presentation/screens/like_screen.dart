import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../feed/domain/entities/feed_entity.dart';
import '../../../feed/presentation/widgets/feed_card.dart';
import '../providers/like_provider.dart';

class LikeScreen extends ConsumerStatefulWidget {
  const LikeScreen({super.key});

  @override
  ConsumerState<LikeScreen> createState() => _LikeScreenState();
}

class _LikeScreenState extends ConsumerState<LikeScreen> {
  bool _isGridMode = true;

  @override
  Widget build(BuildContext context) {
    final likeState = ref.watch(likeProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header: Back + Logo ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Center(
                child: Image.asset(
                  'assets/images/logo_header.png',
                  height: 34,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.circle,
                    size: 34,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),

            // ── Toggle bar: List / Grid ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isGridMode = false),
                    child: Icon(
                      Icons.view_agenda_outlined,
                      color: _isGridMode
                          ? AppTheme.textSecondary
                          : AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _isGridMode = true),
                    child: Icon(
                      Icons.grid_view_outlined,
                      color: _isGridMode
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Content ──
            Expanded(
              child: likeState.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            '좋아요한 게시물이 없습니다',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_isGridMode) {
                    return _buildGridView(posts);
                  } else {
                    return _buildListView(posts);
                  }
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error: $error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grid View ──
  Widget _buildGridView(List<FeedEntity> posts) {
    return GridView.builder(
      padding: const EdgeInsets.only(left: 9, right: 9, top: 8, bottom: 130),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 7,
        mainAxisSpacing: 8,
        childAspectRatio: 124 / 133,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return _GridCard(
          item: posts[index],
          onTap: () => _showFeedDetail(context, posts, index),
        );
      },
    );
  }

  // ── List View: reuse FeedCard from the main feed ──
  Widget _buildListView(List<FeedEntity> posts) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 130),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return FeedCard(item: posts[index]);
      },
    );
  }

  // ── Show feed detail when grid photo is tapped ──
  void _showFeedDetail(
      BuildContext context, List<FeedEntity> posts, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FeedDetailPage(
          posts: posts,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

// ── Full-page feed detail (scrollable list starting from tapped post) ──
class _FeedDetailPage extends StatelessWidget {
  const _FeedDetailPage({
    required this.posts,
    required this.initialIndex,
  });

  final List<FeedEntity> posts;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final controller = ScrollController(initialScrollOffset: 0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppTheme.primaryColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          '좋아요한 게시물',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.only(bottom: 40),
        // Show the tapped post first, then the rest after it
        itemCount: posts.length,
        itemBuilder: (context, index) {
          // Reorder: start from initialIndex, wrap around
          final reorderedIndex = (initialIndex + index) % posts.length;
          return FeedCard(item: posts[reorderedIndex]);
        },
      ),
    );
  }
}

// ── Grid Card (Figma: rounded 9px, #E6E6E6, shadow) ──
class _GridCard extends StatelessWidget {
  final FeedEntity item;
  final VoidCallback onTap;

  const _GridCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(9),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: CachedNetworkImage(
            imageUrl: item.url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: AppTheme.lightGrey,
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: AppTheme.lightGrey,
              child: const Icon(Icons.broken_image_outlined,
                  size: 20, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}
