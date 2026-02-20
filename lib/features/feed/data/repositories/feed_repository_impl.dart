import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/feed_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/feed_repository.dart';

import 'package:firebase_storage/firebase_storage.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Stream<List<FeedEntity>> getFeedStream() {
    return _firestore
        .collection('posts')
        .where('status', isEqualTo: 'RELEASED')
        .where('visibility', isEqualTo: 'PUBLIC')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FeedEntity.fromFirestore(doc)).toList();
    });
  }

  @override
  Stream<List<FeedEntity>> getMyFeedStream(String userId) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FeedEntity.fromFirestore(doc)).toList();
    });
  }

  @override
  Stream<List<FeedEntity>> getLikedFeedStream(String userId) {
    return _firestore
        .collection('posts')
        .where('likedBy', arrayContains: userId)
        .where('status', isEqualTo: 'RELEASED')
        .where('visibility', isEqualTo: 'PUBLIC')
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => FeedEntity.fromFirestore(doc)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  @override
  Stream<FeedEntity?> getLatestPostForUser(String userId) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return FeedEntity.fromFirestore(snapshot.docs.first);
    });
  }

  @override
  Future<List<FeedEntity>> getUserPostsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final querySnapshot = await _firestore
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .where('status', isEqualTo: 'RELEASED')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThan: Timestamp.fromDate(endDate))
        .orderBy('createdAt', descending: false)
        .get();

    return querySnapshot.docs
        .map((doc) => FeedEntity.fromFirestore(doc))
        .toList();
  }

  @override
  Stream<List<FeedEntity>> watchUserPostsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .where('status', isEqualTo: 'RELEASED')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThan: Timestamp.fromDate(endDate))
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FeedEntity.fromFirestore(doc)).toList());
  }

  @override
  Stream<FeedEntity?> getMyPendingPost(String userId) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .where('status', isEqualTo: 'PENDING')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return FeedEntity.fromFirestore(snapshot.docs.first);
    });
  }

  @override
  Future<FeedEntity?> getPostById(String postId) async {
    final doc = await _firestore.collection('posts').doc(postId).get();
    if (!doc.exists) {
      return null;
    }

    return FeedEntity.fromFirestore(doc);
  }

  @override
  Future<void> deletePost(String postId, String imageUrl) async {
    // 1. Delete from Firestore
    await _firestore.collection('posts').doc(postId).delete();

    // 2. Delete from Storage
    try {
      await _storage.refFromURL(imageUrl).delete();
    } catch (e) {
      // Ignore if image is already deleted or not found
      // debugPrint('Error deleting image: $e');
    }
  }

  @override
  Future<void> toggleLike(String postId, String userId, bool isLiked) async {
    final docRef = _firestore.collection('posts').doc(postId);

    if (isLiked) {
      // Currently liked, so remove like
      await docRef.update({
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    } else {
      // Not liked, so add like
      await docRef.update({
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    }
  }

  @override
  Future<void> updatePostCaption(String postId, String newCaption) async {
    await _firestore.collection('posts').doc(postId).update({
      'caption': newCaption,
      'content': newCaption,
    });
  }

  @override
  Stream<List<CommentEntity>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommentEntity.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> addComment(String postId, String userId, String text) async {
    final batch = _firestore.batch();

    final commentRef =
        _firestore.collection('posts').doc(postId).collection('comments').doc();
    batch.set(commentRef, {
      'postId': postId,
      'userId': userId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Increment commentCount on the post
    final postRef = _firestore.collection('posts').doc(postId);
    batch.update(postRef, {
      'commentCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    final batch = _firestore.batch();

    final commentRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);
    batch.delete(commentRef);

    final postRef = _firestore.collection('posts').doc(postId);
    batch.update(postRef, {
      'commentCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }
}
