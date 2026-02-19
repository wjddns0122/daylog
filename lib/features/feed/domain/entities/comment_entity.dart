import 'package:cloud_firestore/cloud_firestore.dart';

class CommentEntity {
  final String id;
  final String postId;
  final String userId;
  final String text;
  final DateTime createdAt;

  CommentEntity({
    required this.id,
    required this.postId,
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  factory CommentEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentEntity(
      id: doc.id,
      postId: data['postId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
