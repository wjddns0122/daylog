import 'package:daylog/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:daylog/features/social/presentation/providers/social_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(type == FollowListType.followers ? '팔로워' : '팔로잉'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: listAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Text(
                type == FollowListType.followers
                    ? '아직 팔로워가 없어요.'
                    : '아직 팔로우한 사용자가 없어요.',
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      user.photoUrl != null && user.photoUrl!.isNotEmpty
                          ? NetworkImage(user.photoUrl!)
                          : null,
                  child: user.photoUrl == null || user.photoUrl!.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(user.nickname ?? user.displayName),
                subtitle: Text('@${user.nickname ?? user.uid}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('목록을 불러오지 못했어요.\n$error')),
      ),
    );
  }
}
