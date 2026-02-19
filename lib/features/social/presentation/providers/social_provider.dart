import 'package:daylog/features/auth/domain/models/user_model.dart';
import 'package:daylog/features/social/data/repositories/social_repository_impl.dart';
import 'package:daylog/features/social/domain/repositories/social_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepositoryImpl();
});

final socialSearchQueryProvider = StateProvider<String>((ref) => '');

final socialSearchProvider = FutureProvider<List<UserModel>>((ref) async {
  final query = ref.watch(socialSearchQueryProvider).trim();
  if (query.isEmpty) {
    return const [];
  }

  final repository = ref.watch(socialRepositoryProvider);
  return repository.searchUsers(query);
});

final relationshipProvider =
    StreamProvider.family<RelationshipState, String>((ref, targetUserId) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.watchRelationship(targetUserId);
});

final incomingFollowRequestsProvider =
    StreamProvider<List<FollowRequestItem>>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.watchIncomingRequests();
});

final followersProvider = StreamProvider.family<List<UserModel>, String>((
  ref,
  userId,
) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.watchFollowers(userId);
});

final followingProvider = StreamProvider.family<List<UserModel>, String>((
  ref,
  userId,
) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.watchFollowing(userId);
});
