import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/user_model.dart';

/// Caches user profile data by UID to avoid repeated Firestore reads.
/// Falls back to Firebase Auth current user info if Firestore doc is missing.
final userProfileProvider =
    FutureProvider.family<UserModel?, String>((ref, uid) async {
  if (uid.isEmpty) return null;

  try {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromDocument(doc);
    }
  } catch (_) {
    // Firestore fetch failed, fall through to Auth fallback
  }

  // Fallback: if the requested uid matches the current Auth user,
  // build a UserModel from Firebase Auth info.
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      return UserModel(
        uid: currentUser.uid,
        email: currentUser.email ?? '',
        displayName: currentUser.displayName ?? '',
        nickname: currentUser.displayName,
        photoUrl: currentUser.photoURL,
        isVerified: currentUser.emailVerified,
      );
    }
  } catch (_) {
    // Auth fallback also failed
  }

  return null;
});
