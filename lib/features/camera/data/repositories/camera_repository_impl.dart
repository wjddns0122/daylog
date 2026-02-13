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
  Future<void> uploadPhoto(File file, String content) async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }

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

      if (content.isEmpty) {
        debugPrint(
            '⚠️ Caption is empty! This might cause "Missing required fields" error if function checks stricter rules.');
      }

      await callable.call(<String, dynamic>{
        'imagePath': downloadUrl,
        'caption': content,
        'requestId': uuid,
      });
    } catch (e) {
      rethrow;
    }
  }
}
