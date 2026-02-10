import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool isVerified;
  final String? nickname;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.isVerified,
    this.nickname,
  });

  // Factory to create from Firebase User
  factory UserModel.fromFirebaseUser(User user, {String? nickname}) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
      isVerified: user.emailVerified,
      nickname: nickname,
    );
  }

  // Factory to create from Firestore Document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw Exception('Document does not exist');
    }

    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      isVerified: data['isVerified'] ?? false,
      nickname: data['nickname'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isVerified': isVerified,
      'nickname': nickname,
      'lastLoginAt': FieldValue.serverTimestamp(),
    };
  }
}
