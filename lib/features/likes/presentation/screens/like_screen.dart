import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../feed/domain/entities/feed_entity.dart';
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
              child: Row(
                children: [
                  // Back chevron
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(Icons.chevron_left,
                          size: 28, color: AppTheme.primaryColor),
                    ),
                  ),
                  const Spacer(),
                  // Center logo
                  Image.asset(
                    'assets/images/logo_header.png',
                    height: 34,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.circle,
                      size: 34,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 34), // balance
                ],
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

  // ── Grid View (Figma-matched) ──
  Widget _buildGridView(List<FeedEntity> posts) {
    return GridView.builder(
      padding: const EdgeInsets.only(left: 9, right: 9, top: 8, bottom: 130),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 7,
        mainAxisSpacing: 8,
        childAspectRatio: 124 / 133, // Figma: w124 x h133
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return _GridCard(item: posts[index]);
      },
    );
  }

  // ── List View ──
  Widget _buildListView(List<FeedEntity> posts) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 130),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final item = posts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: item.url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppTheme.lightGrey,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.lightGrey,
                      child: const Icon(Icons.broken_image_outlined,
                          color: Colors.grey),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite,
                          size: 16, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text(
                        '${item.likedBy.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Grid Card (Figma: rounded 9px, #E6E6E6, shadow) ──
class _GridCard extends StatelessWidget {
  final FeedEntity item;
  const _GridCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000), // rgba(0,0,0,0.25)
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
    );
  }
}
