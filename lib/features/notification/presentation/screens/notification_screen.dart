import 'package:daylog/core/theme/app_theme.dart';
import 'package:daylog/features/camera/presentation/screens/result_screen.dart';
import 'package:daylog/features/feed/presentation/providers/feed_provider.dart';
import 'package:daylog/features/notification/domain/entities/notification_entity.dart';
import 'package:daylog/features/notification/presentation/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends HookConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future<void>(() async {
        await ref.read(notificationRepositoryProvider).markAllAsRead();
      });
      return null;
    }, const []);

    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Notifications',
          style: GoogleFonts.lora(
            color: AppTheme.primaryColor,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _NotificationTile(
                notification: item,
                onTap: () => _handleTap(context, ref, item),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load notifications.\n$error',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                color: AppTheme.primaryColor,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    NotificationEntity item,
  ) async {
    switch (item.type) {
      case NotificationType.filmDeveloped:
        final relatedPostId = item.relatedPostId;
        if (relatedPostId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post not found.')),
          );
          return;
        }

        final post = await ref.read(feedRepositoryProvider).getPostById(
              relatedPostId,
            );
        if (!context.mounted) {
          return;
        }

        if (post == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post not found.')),
          );
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ResultScreen(post: post),
          ),
        );
        break;
      case NotificationType.like:
      case NotificationType.comment:
      case NotificationType.followAccepted:
        context.go('/profile/followers');
        break;
      case NotificationType.followRequest:
        context.push('/follow-requests');
        break;
      case NotificationType.followRejected:
        context.go('/search-users');
        break;
      case NotificationType.system:
        context.go('/');
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationEntity notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, h:mm a');
    final icon = switch (notification.type) {
      NotificationType.like => Icons.favorite_rounded,
      NotificationType.comment => Icons.chat_bubble_rounded,
      NotificationType.filmDeveloped => Icons.auto_awesome_rounded,
      NotificationType.followRequest => Icons.person_add_alt_1_rounded,
      NotificationType.followAccepted => Icons.how_to_reg_rounded,
      NotificationType.followRejected => Icons.person_off_rounded,
      NotificationType.system => Icons.notifications_rounded,
    };
    final iconColor = switch (notification.type) {
      NotificationType.like => const Color(0xFFE06767),
      NotificationType.comment => const Color(0xFF567D9A),
      NotificationType.filmDeveloped => const Color(0xFF8C7A5B),
      NotificationType.followRequest => const Color(0xFF4D6B8A),
      NotificationType.followAccepted => const Color(0xFF3E8A5A),
      NotificationType.followRejected => const Color(0xFF8A5A3E),
      NotificationType.system => const Color(0xFF616161),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: notification.isRead ? const Color(0xFFE5E5E5) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.lora(
                              color: AppTheme.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE06767),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: GoogleFonts.lora(
                        color: const Color(0xFF505050),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatter.format(notification.createdAt),
                      style: GoogleFonts.lora(
                        color: const Color(0xFF8A8A8A),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 36,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No notifications yet',
              style: GoogleFonts.lora(
                color: AppTheme.primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'When social activity or film updates happen, notifications will show up here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                color: const Color(0xFF7A7A7A),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
