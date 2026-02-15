import 'dart:io';

abstract class CameraRepository {
  Future<String?> pickImage();
  Future<void> uploadPhoto(File file, String content, String visibility);
}
