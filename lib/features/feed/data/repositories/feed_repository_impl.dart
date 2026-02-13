import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/feed_entity.dart';
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
}
