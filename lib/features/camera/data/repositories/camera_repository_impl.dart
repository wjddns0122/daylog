import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/repositories/camera_repository.dart';

class CameraRepositoryImpl implements CameraRepository {
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  @override
  Future<String?> pickImage() async {
    // CRITICAL: Use gallery as requested
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }

  @override
  Future<void> uploadPhoto(File file, String content) async {
    // 1. Authenticate anonymously
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }

    // 2. Upload file to Storage
    final String uuid = _uuid.v4();
    final Reference ref = _storage.ref().child('shots/$uuid.jpg');
    final UploadTask uploadTask = ref.putFile(file);
    final TaskSnapshot snapshot = await uploadTask;
    final String downloadUrl = await snapshot.ref.getDownloadURL();

    // 3. Save to Firestore
    await _firestore.collection('shots').add({
      'url': downloadUrl,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': _auth.currentUser?.uid,
    });
  }
}
