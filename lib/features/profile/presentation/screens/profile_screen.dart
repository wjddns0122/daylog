import 'package:daylog/core/theme/app_theme.dart';
import 'package:daylog/features/auth/domain/models/user_model.dart';
import 'package:daylog/features/feed/presentation/providers/user_profile_provider.dart';
import 'package:daylog/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:daylog/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:daylog/features/profile/presentation/widgets/profile_header.dart';
import 'package:daylog/features/social/domain/repositories/social_repository.dart';
import 'package:daylog/features/social/presentation/providers/social_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.userId});

  final String? userId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  RelationshipState? _optimisticRelationship;
  bool _isFollowActionInFlight = false;

  Future<void> _toggleFollow(
      String targetUserId, RelationshipState state) async {
    if (_isFollowActionInFlight) {
      return;
    }

    final nextState = state == RelationshipState.following
        ? RelationshipState.none
        : RelationshipState.following;

    setState(() {
      _isFollowActionInFlight = true;
      _optimisticRelationship = nextState;
    });

    try {
      final repository = ref.read(socialRepositoryProvider);
      if (state == RelationshipState.following) {
        await repository.unfollow(targetUserId);
      } else {
        await repository.sendFollowRequest(targetUserId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('팔로잉 처리 중 오류가 발생했어요: $e')),
        );
      }
      setState(() {
        _optimisticRelationship = state;
      });
    } finally {
      ref.invalidate(relationshipProvider(targetUserId));
      ref.invalidate(followersProvider(targetUserId));
      final currentUid = ref.read(authViewModelProvider).valueOrNull?.uid;
      if (currentUid != null) {
        ref.invalidate(followingProvider(currentUid));
      }
      if (mounted) {
        setState(() {
          _isFollowActionInFlight = false;
          _optimisticRelationship = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final authUser = authState.valueOrNull;
    final isOwnProfile =
        widget.userId == null || widget.userId == authUser?.uid;
    final targetUid = isOwnProfile ? authUser?.uid : widget.userId;
    final profileUserAsync = targetUid == null
        ? const AsyncValue.data(null)
        : ref.watch(userProfileStreamProvider(targetUid));
    final user =
        profileUserAsync.valueOrNull ?? (isOwnProfile ? authUser : null);
    final relationAsync = !isOwnProfile && user != null
        ? ref.watch(relationshipProvider(user.uid))
        : const AsyncValue<RelationshipState>.data(RelationshipState.none);
    final relationship = _optimisticRelationship ??
        relationAsync.valueOrNull ??
        RelationshipState.none;

    final profileState = user != null
        ? ref.watch(profileViewModelProvider(user.uid))
        : const ProfileState();
    final followersAsync = user != null
        ? ref.watch(followersProvider(user.uid))
        : const AsyncValue<List<UserModel>>.data([]);
    final followingAsync = user != null
        ? ref.watch(followingProvider(user.uid))
        : const AsyncValue<List<UserModel>>.data([]);
    final followerCount =
        followersAsync.valueOrNull?.length ?? user?.followersCount ?? 0;
    final followingCount =
        followingAsync.valueOrNull?.length ?? user?.followingCount ?? 0;

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
          if (user == null || profileUserAsync.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SliverToBoxAdapter(
              child: ProfileHeader(
                handle: user.nickname ?? '', // Assuming Handle is Nickname
                avatarUrl: user.photoUrl,
                bio: (user.bio == null || user.bio!.trim().isEmpty)
                    ? '한 줄 소개가 아직 없어요.'
                    : user.bio!,
                joinDate: formattedDate,
                postCount: profileState.posts.length,
                followerCount: followerCount,
                followingCount: followingCount,
                onTapFollowers: isOwnProfile
                    ? () => context.push('/profile/followers')
                    : null,
                onTapFollowing: isOwnProfile
                    ? () => context.push('/profile/following')
                    : null,
                actionButtonLabel: isOwnProfile
                    ? '프로필 편집'
                    : (relationship == RelationshipState.following
                        ? '언팔로잉'
                        : '팔로잉'),
                isActionButtonLoading: !isOwnProfile && _isFollowActionInFlight,
                onActionButtonPressed: isOwnProfile
                    ? () => context.push('/profile/edit')
                    : () => _toggleFollow(user.uid, relationship),
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
                      return GestureDetector(
                        onTap: () {
                          context.push(
                            '/users/${user.uid}/posts',
                            extra: {
                              'initialPostId': post.id,
                              'title': user.nickname ?? user.displayName,
                            },
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            image: post.url.isNotEmpty == true
                                ? DecorationImage(
                                    image: NetworkImage(post.url),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
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
