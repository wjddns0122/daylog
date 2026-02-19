import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/repositories/camera_repository.dart';

class CameraRepositoryImpl implements CameraRepository {
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final Uuid _uuid = const Uuid();

  @override
  Future<String?> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }

  @override
  Future<List<String>> suggestMoodKeywords(String imageUrl) async {
    debugPrint('🏷️ [MoodKeywords] Calling suggestMoodKeywords...');

    if (_auth.currentUser == null) {
      debugPrint('🔐 [Auth] No Firebase user, signing in anonymously...');
      await _auth.signInAnonymously();
    }

    try {
      final HttpsCallable callable =
          _functions.httpsCallable('suggestMoodKeywords');
      final result = await callable.call(<String, dynamic>{
        'imageUrl': imageUrl,
      });

      final data = result.data as Map<String, dynamic>?;
      if (data != null && data['keywords'] != null) {
        final keywords = List<String>.from(data['keywords'] as List);
        debugPrint('🏷️ [MoodKeywords] Got keywords: $keywords');
        return keywords;
      }
    } catch (e) {
      debugPrint('🏷️ [MoodKeywords] Failed: $e');
    }

    // Fallback defaults
    return ['감성적', '따뜻한', '잔잔한', '추억', '평화로운'];
  }

  @override
  Future<void> uploadPhoto(File file, String content, String visibility,
      List<String> moodKeywords) async {
    debugPrint('🔐 [Auth] currentUser before check: ${_auth.currentUser?.uid}');

    if (_auth.currentUser == null) {
      debugPrint('🔐 [Auth] No Firebase user, signing in anonymously...');
      try {
        final cred = await _auth.signInAnonymously();
        debugPrint('🔐 [Auth] Anonymous sign-in OK: uid=${cred.user?.uid}');
      } catch (e) {
        debugPrint('🔐 [Auth] Anonymous sign-in FAILED: $e');
        rethrow;
      }
    } else {
      debugPrint('🔐 [Auth] User exists, refreshing token...');
      try {
        final token = await _auth.currentUser!.getIdToken(true);
        debugPrint('🔐 [Auth] Token refreshed OK (length=${token?.length})');
      } catch (e) {
        debugPrint('🔐 [Auth] Token refresh FAILED: $e');
      }
    }

    debugPrint('🔐 [Auth] Final currentUser: ${_auth.currentUser?.uid}');
    debugPrint('🔐 [Auth] isAnonymous: ${_auth.currentUser?.isAnonymous}');

    final String uuid = _uuid.v4();
    final Reference ref = _storage.ref().child('shots/$uuid.jpg');
    final UploadTask uploadTask = ref.putFile(file);
    final TaskSnapshot snapshot = await uploadTask;
    final String downloadUrl = await snapshot.ref.getDownloadURL();

    try {
      final HttpsCallable callable =
          _functions.httpsCallable('createPostIntent');

      debugPrint('📸 [CameraRepo] Calling createPostIntent');
      debugPrint('   - imagePath (downloadUrl): $downloadUrl');
      debugPrint('   - caption: $content');
      debugPrint('   - requestId: $uuid');
      debugPrint('   - visibility: $visibility');
      debugPrint('   - moodKeywords: $moodKeywords');

      await callable.call(<String, dynamic>{
        'imagePath': downloadUrl,
        'caption': content,
        'requestId': uuid,
        'visibility': visibility,
        'moodKeywords': moodKeywords,
      });
    } catch (e) {
      rethrow;
    }
  }
}
