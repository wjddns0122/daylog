import 'package:daylog/core/theme/app_theme.dart';
import 'package:daylog/features/feed/presentation/providers/user_profile_provider.dart';
import 'package:daylog/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:daylog/features/auth/domain/models/user_model.dart';
import 'package:daylog/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:daylog/features/profile/presentation/widgets/profile_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key, this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final authUser = authState.valueOrNull;
    final viewedUserAsync = userId == null
        ? const AsyncValue<UserModel?>.data(null)
        : ref.watch(userProfileProvider(userId!));
    final viewedUser = viewedUserAsync.valueOrNull;

    final isOwnProfile = userId == null || userId == authUser?.uid;
    final user = isOwnProfile ? authUser : viewedUser;

    final profileState = user != null
        ? ref.watch(profileViewModelProvider(user.uid))
        : const ProfileState();

    String formattedDate = '';
    if (user?.createdAt != null) {
      formattedDate = DateFormat('yyyy년 M월에 가입함').format(user!.createdAt!);
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              '@${user?.nickname ?? ''}',
              style: AppTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            centerTitle: false,
            backgroundColor: AppTheme.backgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            actions: [
              if (isOwnProfile)
                IconButton(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(
                    Icons.menu,
                    color: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
          if (user == null || viewedUserAsync.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SliverToBoxAdapter(
              child: ProfileHeader(
                handle: user.nickname ?? '', // Assuming Handle is Nickname
                avatarUrl: user.photoUrl,
                bio:
                    '반가워요! 방문 감사합니다! :0', // Placeholder or add 'bio' to UserModel
                joinDate: formattedDate,
                postCount: profileState.posts.length,
                followerCount: user.followersCount,
                followingCount: user.followingCount,
                onTapFollowers: isOwnProfile
                    ? () => context.push('/profile/followers')
                    : null,
                onTapFollowing: isOwnProfile
                    ? () => context.push('/profile/following')
                    : null,
                showEditProfileButton: isOwnProfile,
                onEditProfile: isOwnProfile
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('프로필 편집 기능 준비 중입니다.')),
                        );
                      }
                    : null,
              ),
            ),

            // Grid
            if (profileState.posts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    "아직 게시물이 없어요.",
                    style: AppTheme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal:
                        0), // Instagram has no side padding usually, just spacing
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2, // Tight spacing
                    crossAxisSpacing: 2,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = profileState.posts[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          image: post.url.isNotEmpty == true
                              ? DecorationImage(
                                  image: NetworkImage(post.url),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                      );
                    },
                    childCount: profileState.posts.length,
                  ),
                ),
              ),
          ],
          const SliverPadding(
              padding: EdgeInsets.only(bottom: 130)), // Nav bar clearance
        ],
      ),
    );
  }
}
