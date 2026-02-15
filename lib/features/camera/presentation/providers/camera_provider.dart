import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/camera_repository_impl.dart';
import '../../domain/repositories/camera_repository.dart';
import '../../data/datasources/ai_service.dart';

final cameraRepositoryProvider = Provider<CameraRepository>((ref) {
  return CameraRepositoryImpl();
});

class CameraState {
  final String? imagePath;
  final bool isLoading;
  final bool isGeneratingCaption;

  CameraState({
    this.imagePath,
    this.isLoading = false,
    this.isGeneratingCaption = false,
  });

  CameraState copyWith({
    String? imagePath,
    bool? isLoading,
    bool? isGeneratingCaption,
  }) {
    return CameraState(
      imagePath: imagePath ?? this.imagePath,
      isLoading: isLoading ?? this.isLoading,
      isGeneratingCaption: isGeneratingCaption ?? this.isGeneratingCaption,
    );
  }
}

class CameraNotifier extends StateNotifier<CameraState> {
  final CameraRepository _repository;
  final AiService _aiService;

  CameraNotifier(this._repository)
      : _aiService = AiService(),
        super(CameraState());

  void setImage(String? path) {
    state = state.copyWith(imagePath: path);
  }

  Future<String?> generateCaption() async {
    if (state.imagePath == null) return null;

    state = state.copyWith(isGeneratingCaption: true);
    try {
      final caption = await _aiService.generateJournalFromImage(
        File(state.imagePath!),
      );
      return caption;
    } catch (e) {
      // Handle error gracefully or rethrow
      return null;
    } finally {
      state = state.copyWith(isGeneratingCaption: false);
    }
  }

  Future<void> uploadCurrentPhoto(String content,
      {String visibility = 'PRIVATE'}) async {
    if (state.imagePath == null) return;

    state = state.copyWith(isLoading: true);
    try {
      await _repository.uploadPhoto(
          File(state.imagePath!), content, visibility);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>((
  ref,
) {
  return CameraNotifier(ref.watch(cameraRepositoryProvider));
});
