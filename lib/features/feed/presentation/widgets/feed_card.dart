import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/feed_entity.dart';
import '../providers/feed_provider.dart';
import '../providers/user_profile_provider.dart';
import 'comments_sheet.dart';

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

    // Fetch the post author's profile
    final authorAsync = ref.watch(
      userProfileProvider(item.userId ?? ''),
    );

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
          // Header — real user info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (item.userId != null) {
                      context.push('/profile');
                    }
                  },
                  child: Row(
                    children: [
                      // Avatar from Firestore user profile
                      authorAsync.when(
                        data: (authorUser) {
                          if (authorUser?.photoUrl != null &&
                              authorUser!.photoUrl!.isNotEmpty) {
                            return CircleAvatar(
                              radius: 18,
                              backgroundImage:
                                  NetworkImage(authorUser.photoUrl!),
                              backgroundColor: Colors.grey[200],
                            );
                          }
                          return const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white),
                          );
                        },
                        loading: () => CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[200],
                        ),
                        error: (_, __) => const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Real username
                          authorAsync.when(
                            data: (authorUser) => Text(
                              authorUser?.nickname ??
                                  authorUser?.displayName ??
                                  '사용자',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            loading: () => Container(
                              width: 80,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            error: (_, __) => const Text(
                              '사용자',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(item.timestamp),
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
                          '삭제하기',
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

          // Action Row — like + comment (no bookmark)
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
                GestureDetector(
                  onTap: () => showCommentsSheet(context, item.id),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 26,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Likes & commentCount & Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '좋아요 ${item.likedBy.length}개',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (item.content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      children: [
                        // Author name bold
                        TextSpan(
                          text: authorAsync.whenOrNull(
                                data: (u) => u?.nickname ?? u?.displayName,
                              ) ??
                              '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: '  '),
                        TextSpan(text: item.content),
                      ],
                    ),
                  ),
                ],
                if (item.commentCount > 0) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => showCommentsSheet(context, item.id),
                    child: Text(
                      '댓글 ${item.commentCount}개 모두 보기',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('yyyy.MM.dd').format(dt);
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
        title: const Text('게시글 삭제'),
        content: const Text('삭제하면 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(feedProvider.notifier).deletePost(postId, imageUrl);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('게시글이 삭제되었습니다.')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
