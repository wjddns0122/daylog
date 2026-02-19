import 'dart:async';

import 'package:daylog/core/theme/app_theme.dart';
import 'package:daylog/features/social/domain/repositories/social_repository.dart';
import 'package:daylog/features/social/presentation/providers/social_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  final Map<String, RelationshipState> _optimisticStates = {};
  final Set<String> _inFlightUserIds = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(socialSearchQueryProvider.notifier).state = value;
    });
  }

  Future<void> _toggleFollow({
    required BuildContext context,
    required String targetUserId,
    required RelationshipState currentState,
  }) async {
    if (_inFlightUserIds.contains(targetUserId)) {
      return;
    }

    final nextState = currentState == RelationshipState.following
        ? RelationshipState.none
        : RelationshipState.following;

    setState(() {
      _inFlightUserIds.add(targetUserId);
      _optimisticStates[targetUserId] = nextState;
    });

    try {
      final repository = ref.read(socialRepositoryProvider);
      if (currentState == RelationshipState.following) {
        await repository.unfollow(targetUserId);
      } else {
        await repository.sendFollowRequest(targetUserId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('처리 중 오류가 발생했어요: $e')),
        );
      }
      setState(() {
        _optimisticStates[targetUserId] = currentState;
      });
    } finally {
      ref.invalidate(relationshipProvider(targetUserId));
      if (mounted) {
        setState(() {
          _inFlightUserIds.remove(targetUserId);
          _optimisticStates.remove(targetUserId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(socialSearchQueryProvider);
    final searchAsync = ref.watch(socialSearchProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('친구 찾기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: '닉네임으로 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: query.trim().isEmpty
                  ? const Center(child: Text('검색어를 입력하세요.'))
                  : searchAsync.when(
                      data: (users) {
                        if (users.isEmpty) {
                          return const Center(child: Text('검색 결과가 없어요.'));
                        }

                        return ListView.separated(
                          itemCount: users.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final relationshipAsync =
                                ref.watch(relationshipProvider(user.uid));
                            final resolvedState = _optimisticStates[user.uid] ??
                                relationshipAsync.valueOrNull ??
                                RelationshipState.none;
                            final isBusy = _inFlightUserIds.contains(user.uid);

                            return ListTile(
                              onTap: () => context.push('/users/${user.uid}'),
                              leading: CircleAvatar(
                                backgroundImage: (user.photoUrl != null &&
                                        user.photoUrl!.isNotEmpty)
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                                child: (user.photoUrl == null ||
                                        user.photoUrl!.isEmpty)
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(user.nickname ?? user.displayName),
                              subtitle: Text('@${user.nickname ?? user.uid}'),
                              trailing: _FollowActionButton(
                                state: resolvedState,
                                isBusy: isBusy,
                                onPressed: () => _toggleFollow(
                                  context: context,
                                  targetUserId: user.uid,
                                  currentState: resolvedState,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, _) => Center(
                        child: Text('검색 중 오류가 발생했어요.\n$error'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowActionButton extends StatelessWidget {
  const _FollowActionButton({
    required this.state,
    required this.onPressed,
    required this.isBusy,
  });

  final RelationshipState state;
  final VoidCallback onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      RelationshipState.none => '팔로우',
      RelationshipState.following => '팔로잉',
    };

    return OutlinedButton(
      onPressed: isBusy ? null : onPressed,
      child: isBusy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
