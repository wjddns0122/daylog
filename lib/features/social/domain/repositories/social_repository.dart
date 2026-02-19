import 'package:daylog/features/auth/domain/models/user_model.dart';

enum RelationshipState { none, following }

class FollowRequestItem {
  const FollowRequestItem({
    required this.id,
    required this.requesterId,
    required this.targetUserId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String requesterId;
  final String targetUserId;
  final String status;
  final DateTime createdAt;
}

abstract class SocialRepository {
  Future<List<UserModel>> searchUsers(String query, {int limit = 20});
  Stream<RelationshipState> watchRelationship(String targetUserId);
  Stream<List<FollowRequestItem>> watchIncomingRequests();
  Stream<List<UserModel>> watchFollowers(String userId);
  Stream<List<UserModel>> watchFollowing(String userId);

  Future<void> sendFollowRequest(String targetUserId);
  Future<void> cancelFollowRequest(String targetUserId);
  Future<void> acceptFollowRequest(String requestId);
  Future<void> rejectFollowRequest(String requestId);
  Future<void> unfollow(String targetUserId);
}
