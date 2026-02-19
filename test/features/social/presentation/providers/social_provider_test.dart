import 'package:daylog/features/auth/domain/models/user_model.dart';
import 'package:daylog/features/social/domain/repositories/social_repository.dart';
import 'package:daylog/features/social/presentation/providers/social_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('socialSearchProvider returns empty when query is blank', () async {
    final container = ProviderContainer(
      overrides: [
        socialRepositoryProvider.overrideWithValue(_FakeSocialRepository()),
      ],
    );
    addTearDown(container.dispose);

    container.read(socialSearchQueryProvider.notifier).state = '   ';

    final result = await container.read(socialSearchProvider.future);
    expect(result, isEmpty);
  });

  test('socialSearchProvider returns repository users when query exists',
      () async {
    final container = ProviderContainer(
      overrides: [
        socialRepositoryProvider.overrideWithValue(_FakeSocialRepository()),
      ],
    );
    addTearDown(container.dispose);

    container.read(socialSearchQueryProvider.notifier).state = 'ann';

    final result = await container.read(socialSearchProvider.future);
    expect(result, hasLength(2));
    expect(result.first.nickname, 'anna');
    expect(result.last.nickname, 'annie');
  });

  test('relationshipProvider exposes following state from repository stream',
      () async {
    final container = ProviderContainer(
      overrides: [
        socialRepositoryProvider.overrideWithValue(_FakeSocialRepository()),
      ],
    );
    addTearDown(container.dispose);

    final value =
        await container.read(relationshipProvider('target_01').future);
    expect(value, RelationshipState.following);
  });
}

class _FakeSocialRepository implements SocialRepository {
  @override
  Future<void> acceptFollowRequest(String requestId) async {}

  @override
  Future<void> cancelFollowRequest(String targetUserId) async {}

  @override
  Future<void> rejectFollowRequest(String requestId) async {}

  @override
  Future<void> sendFollowRequest(String targetUserId) async {}

  @override
  Future<void> unfollow(String targetUserId) async {}

  @override
  Stream<List<FollowRequestItem>> watchIncomingRequests() {
    return Stream.value(const []);
  }

  @override
  Stream<RelationshipState> watchRelationship(String targetUserId) {
    return Stream.value(RelationshipState.following);
  }

  @override
  Stream<List<UserModel>> watchFollowers(String userId) {
    return Stream.value(const []);
  }

  @override
  Stream<List<UserModel>> watchFollowing(String userId) {
    return Stream.value(const []);
  }

  @override
  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) {
      return const [];
    }

    return const [
      UserModel(
        uid: 'u1',
        email: 'anna@example.com',
        displayName: 'Anna',
        nickname: 'anna',
      ),
      UserModel(
        uid: 'u2',
        email: 'annie@example.com',
        displayName: 'Annie',
        nickname: 'annie',
      ),
    ];
  }
}
