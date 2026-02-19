import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:daylog/features/auth/domain/models/user_model.dart';
import 'package:daylog/features/social/domain/repositories/social_repository.dart';

class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  String get _currentUid => _auth.currentUser?.uid ?? '';

  @override
  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    final uid = _currentUid;
    if (uid.isEmpty) {
      return const [];
    }

    final normalized = _normalizeQuery(query);
    if (normalized.isEmpty) {
      return const [];
    }

    final uniqueById = <String, UserModel>{};

    try {
      final nicknameSnapshot = await _firestore
          .collection('users')
          .where('nicknameLower', isGreaterThanOrEqualTo: normalized)
          .where('nicknameLower', isLessThan: '$normalized\uf8ff')
          .orderBy('nicknameLower')
          .limit(limit)
          .get();

      final displayNameSnapshot = await _firestore
          .collection('users')
          .where('displayNameLower', isGreaterThanOrEqualTo: normalized)
          .where('displayNameLower', isLessThan: '$normalized\uf8ff')
          .orderBy('displayNameLower')
          .limit(limit)
          .get();

      final allDocs = [...nicknameSnapshot.docs, ...displayNameSnapshot.docs];
      _appendSearchMatches(
        docs: allDocs,
        currentUid: uid,
        normalizedQuery: normalized,
        uniqueById: uniqueById,
        checkRawFields: false,
      );
    } catch (e) {
      debugPrint('DEBUG searchUsers indexed query failed: $e');
    }

    if (uniqueById.length < limit) {
      await _appendFallbackMatches(
        currentUid: uid,
        normalizedQuery: normalized,
        limit: limit,
        uniqueById: uniqueById,
      );
    }

    return uniqueById.values.take(limit).toList();
  }

  String _normalizeQuery(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.startsWith('@')) {
      return trimmed.substring(1).trim();
    }
    return trimmed;
  }

  Future<void> _appendFallbackMatches({
    required String currentUid,
    required String normalizedQuery,
    required int limit,
    required Map<String, UserModel> uniqueById,
  }) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection('users').orderBy(FieldPath.documentId).limit(200);

    const maxPages = 10;
    for (var page = 0; page < maxPages && uniqueById.length < limit; page++) {
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        break;
      }

      _appendSearchMatches(
        docs: snapshot.docs,
        currentUid: currentUid,
        normalizedQuery: normalizedQuery,
        uniqueById: uniqueById,
        checkRawFields: true,
      );

      query = _firestore
          .collection('users')
          .orderBy(FieldPath.documentId)
          .startAfterDocument(snapshot.docs.last)
          .limit(200);
    }
  }

  void _appendSearchMatches({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String currentUid,
    required String normalizedQuery,
    required Map<String, UserModel> uniqueById,
    required bool checkRawFields,
  }) {
    for (final doc in docs) {
      if (doc.id == currentUid || uniqueById.containsKey(doc.id)) {
        continue;
      }

      if (checkRawFields) {
        final data = doc.data();
        final nickname = (data['nickname'] as String? ?? '').toLowerCase();
        final displayName =
            (data['displayName'] as String? ?? '').toLowerCase();
        final nicknameLower =
            (data['nicknameLower'] as String? ?? '').toLowerCase();
        final displayNameLower =
            (data['displayNameLower'] as String? ?? '').toLowerCase();

        final isMatch = nickname.startsWith(normalizedQuery) ||
            displayName.startsWith(normalizedQuery) ||
            nicknameLower.startsWith(normalizedQuery) ||
            displayNameLower.startsWith(normalizedQuery) ||
            nickname.contains(normalizedQuery) ||
            displayName.contains(normalizedQuery) ||
            nicknameLower.contains(normalizedQuery) ||
            displayNameLower.contains(normalizedQuery);
        if (!isMatch) {
          continue;
        }
      }

      try {
        uniqueById[doc.id] = UserModel.fromDocument(doc);
      } catch (e) {
        debugPrint('DEBUG searchUsers skip malformed doc ${doc.id}: $e');
      }
    }
  }

  @override
  Stream<RelationshipState> watchRelationship(String targetUserId) {
    final uid = _currentUid;
    if (uid.isEmpty || targetUserId.trim().isEmpty) {
      return Stream.value(RelationshipState.none);
    }

    final followDocId = '${uid}_$targetUserId';
    return _firestore.collection('follows').doc(followDocId).snapshots().map(
        (doc) =>
            doc.exists ? RelationshipState.following : RelationshipState.none);
  }

  @override
  Stream<List<FollowRequestItem>> watchIncomingRequests() {
    final uid = _currentUid;
    if (uid.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('follow_requests')
        .where('targetUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'PENDING')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return FollowRequestItem(
            id: doc.id,
            requesterId: data['requesterId'] as String? ?? '',
            targetUserId: data['targetUserId'] as String? ?? '',
            status: data['status'] as String? ?? 'PENDING',
            createdAt: createdAt,
          );
        }).toList();
      },
    );
  }

  @override
  Stream<List<UserModel>> watchFollowers(String userId) {
    return _firestore
        .collection('follows')
        .where('followingId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) => _loadUsersByIds(
              snapshot.docs
                  .map((doc) => doc.data()['followerId'] as String? ?? '')
                  .where((id) => id.isNotEmpty)
                  .toList(),
            ));
  }

  @override
  Stream<List<UserModel>> watchFollowing(String userId) {
    return _firestore
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) => _loadUsersByIds(
              snapshot.docs
                  .map((doc) => doc.data()['followingId'] as String? ?? '')
                  .where((id) => id.isNotEmpty)
                  .toList(),
            ));
  }

  Future<List<UserModel>> _loadUsersByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return const [];
    }

    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }

    final users = <UserModel>[];
    for (final chunk in chunks) {
      final query = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      users.addAll(query.docs.map(UserModel.fromDocument));
    }

    final userMap = {for (final user in users) user.uid: user};
    return ids.map((id) => userMap[id]).whereType<UserModel>().toList();
  }

  Future<void> _call(String name, Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable(name);
    await callable.call(data);
  }

  @override
  Future<void> sendFollowRequest(String targetUserId) {
    return _call('sendFollowRequest', {'targetUserId': targetUserId});
  }

  @override
  Future<void> cancelFollowRequest(String targetUserId) {
    return _call('cancelFollowRequest', {'targetUserId': targetUserId});
  }

  @override
  Future<void> acceptFollowRequest(String requestId) {
    return _call('acceptFollowRequest', {'requestId': requestId});
  }

  @override
  Future<void> rejectFollowRequest(String requestId) {
    return _call('rejectFollowRequest', {'requestId': requestId});
  }

  @override
  Future<void> unfollow(String targetUserId) {
    return _call('unfollowUser', {'targetUserId': targetUserId});
  }
}
