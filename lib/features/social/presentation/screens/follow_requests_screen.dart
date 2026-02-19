import 'package:daylog/features/feed/presentation/providers/user_profile_provider.dart';
import 'package:daylog/features/social/presentation/providers/social_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FollowRequestsScreen extends ConsumerWidget {
  const FollowRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(incomingFollowRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('팔로우 요청'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(child: Text('새로운 팔로우 요청이 없어요.'));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final item = requests[index];
              final userAsync =
                  ref.watch(userProfileProvider(item.requesterId));

              return ListTile(
                leading: userAsync.when(
                  data: (user) => CircleAvatar(
                    backgroundImage:
                        user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                            ? NetworkImage(user.photoUrl!)
                            : null,
                    child: user?.photoUrl == null || user!.photoUrl!.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  loading: () => const CircleAvatar(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, __) =>
                      const CircleAvatar(child: Icon(Icons.person)),
                ),
                title: Text(
                  userAsync.valueOrNull?.nickname ??
                      userAsync.valueOrNull?.displayName ??
                      item.requesterId,
                ),
                subtitle: const Text('님이 팔로우를 요청했습니다.'),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        await ref
                            .read(socialRepositoryProvider)
                            .rejectFollowRequest(item.id);
                      },
                      child: const Text('거절'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        await ref
                            .read(socialRepositoryProvider)
                            .acceptFollowRequest(item.id);
                      },
                      child: const Text('수락'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('요청을 불러오지 못했어요.\n$error')),
      ),
    );
  }
}
