import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/feed_entity.dart';
import '../providers/feed_provider.dart';

class FeedCard extends ConsumerWidget {
  final FeedEntity item;

  const FeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }
    final isLiked = user != null && item.isLiked(user.uid);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/profile'),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '@Day_log1234',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat.yMMMd().format(item.timestamp),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (user != null && item.userId == user.uid)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDelete(context, ref, item.id, item.url);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete Post',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  )
                else
                  const Icon(Icons.more_horiz, color: Colors.grey),
              ],
            ),
          ),

          // Image
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: item.url,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 300,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 300,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
          ),

          // Action Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    ref
                        .read(feedProvider.notifier)
                        .toggleLike(item.id, item.likedBy);
                  },
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? AppTheme.errorColor : Colors.black87,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  tooltip: 'Comments (coming soon)',
                  onPressed: () =>
                      _showFeatureNotice(context, 'Comments are coming soon.'),
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    size: 26,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Bookmark (coming soon)',
                  onPressed: () =>
                      _showFeatureNotice(context, 'Bookmarks are coming soon.'),
                  icon: const Icon(
                    Icons.bookmark_border,
                    size: 28,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Likes & Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.likedBy.length} likes',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (item.content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFeatureNotice(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String postId,
    String imageUrl,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              ref.read(feedProvider.notifier).deletePost(postId, imageUrl);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Post deleted')));
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
