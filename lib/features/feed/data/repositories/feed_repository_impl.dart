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
        .collection('shots')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FeedEntity.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Future<void> deletePost(String postId, String imageUrl) async {
    // 1. Delete from Firestore
    await _firestore.collection('shots').doc(postId).delete();

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
    final docRef = _firestore.collection('shots').doc(postId);

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
