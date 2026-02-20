import 'package:daylog/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:daylog/features/social/presentation/providers/social_provider.dart';
import 'package:daylog/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum FollowListType { followers, following }

class FollowListScreen extends ConsumerWidget {
  const FollowListScreen({
    super.key,
    required this.type,
  });

  final FollowListType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).valueOrNull;
    final uid = user?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final listAsync = type == FollowListType.followers
        ? ref.watch(followersProvider(uid))
        : ref.watch(followingProvider(uid));

    final pageTitle = type == FollowListType.followers ? '팔로워' : '팔로잉';
    final emptyTitle =
        type == FollowListType.followers ? '아직 팔로워가 없어요' : '아직 팔로잉한 친구가 없어요';
    final emptySubtitle = type == FollowListType.followers
        ? '새로운 친구와 연결되면 이곳에 표시돼요.'
        : '검색에서 마음에 드는 친구를 팔로우해보세요.';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        title: Text(pageTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Column(
        children: [
          _ListHeroHeader(title: pageTitle),
          Expanded(
            child: listAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return _EmptyStateCard(
                    title: emptyTitle,
                    subtitle: emptySubtitle,
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _MoodUserTile(
                      title: user.nickname ?? user.displayName,
                      subtitle: '@${user.nickname ?? user.uid}',
                      photoUrl: user.photoUrl,
                      onTap: () => context.push('/users/${user.uid}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '목록을 불러오지 못했어요.\n$error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListHeroHeader extends StatelessWidget {
  const _ListHeroHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFE7E2D9), Color(0xFFD9D2C6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_rounded, color: Color(0xFF4A4338)),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.lora(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3F392F),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodUserTile extends StatelessWidget {
  const _MoodUserTile({
    required this.title,
    required this.subtitle,
    required this.photoUrl,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE9E9E9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                    ? NetworkImage(photoUrl!)
                    : null,
                child: photoUrl == null || photoUrl!.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2F2E2B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        color: const Color(0xFF75706A),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E877E)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFFE8E8E8),
          border: Border.all(color: const Color(0xFFD2D2D2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sentiment_satisfied_alt_rounded,
                size: 34, color: Color(0xFF7B766F)),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4A443A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: const Color(0xFF77716A),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
