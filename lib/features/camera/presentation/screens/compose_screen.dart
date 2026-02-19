import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../providers/camera_provider.dart';

class ComposeScreen extends HookConsumerWidget {
  const ComposeScreen({super.key, required this.imageFile});

  final File imageFile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captionController = useTextEditingController();
    final isUploading = useState(false);
    final isPublic = useState(false);

    // Mood keywords state
    final suggestedKeywords = useState<List<String>>([]);
    final selectedKeywords = useState<Set<String>>({});
    final isLoadingKeywords = useState(false);

    final imageAspectRatioFuture = useMemoized(
      () => _resolveImageAspectRatio(imageFile),
      [imageFile.path],
    );
    final imageAspectRatio = useFuture(imageAspectRatioFuture);

    // Fetch mood keywords on image load
    useEffect(() {
      _fetchMoodKeywords(
        ref: ref,
        imageFile: imageFile,
        suggestedKeywords: suggestedKeywords,
        selectedKeywords: selectedKeywords,
        isLoadingKeywords: isLoadingKeywords,
      );
      return null;
    }, [imageFile.path]);

    Future<void> upload() async {
      if (isUploading.value) return;

      isUploading.value = true;
      try {
        await ref.read(cameraRepositoryProvider).uploadPhoto(
              imageFile,
              captionController.text.trim(),
              isPublic.value ? 'PUBLIC' : 'PRIVATE',
              selectedKeywords.value.toList(),
            );

        if (!context.mounted) return;
        context.go('/pending');
      } catch (e, stack) {
        debugPrint('❌ [Upload] Error: $e');
        debugPrint('❌ [Upload] Stack: $stack');
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF3C3C3C),
            content: Text(
              'Could not upload right now. Please try again.',
              style: GoogleFonts.lora(color: Colors.white),
            ),
          ),
        );
      } finally {
        if (context.mounted) {
          isUploading.value = false;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F1),
        elevation: 0,
        leading: IconButton(
          onPressed:
              isUploading.value ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3D3D3D)),
        ),
        title: Text(
          'Compose',
          style: GoogleFonts.lora(
            color: const Color(0xFF2F2F2F),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ──── Image Preview ────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: AspectRatio(
                            aspectRatio: imageAspectRatio.data ?? (3 / 4),
                            child: Image.file(
                              imageFile,
                              fit: BoxFit.cover,
                              errorBuilder: (context, _, __) => Container(
                                color: const Color(0xFFE6E6E4),
                                alignment: Alignment.center,
                                child: Text(
                                  'Preview unavailable',
                                  style: GoogleFonts.lora(
                                    color: const Color(0xFF787878),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ──── Caption ────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: TextField(
                        controller: captionController,
                        enabled: !isUploading.value,
                        maxLines: 2,
                        minLines: 1,
                        textInputAction: TextInputAction.done,
                        style: GoogleFonts.lora(
                          color: const Color(0xFF3D3D3D),
                          fontSize: 16,
                          height: 1.35,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write a caption...',
                          hintStyle: GoogleFonts.lora(
                            color: const Color(0xFFA2A2A2),
                            fontSize: 16,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    // ──── Mood Keywords ────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.label_outline,
                                    size: 18, color: Color(0xFF777777)),
                                const SizedBox(width: 6),
                                Text(
                                  'AI 무드 키워드',
                                  style: GoogleFonts.lora(
                                    color: const Color(0xFF3D3D3D),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (isLoadingKeywords.value)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '사진에 어울리는 키워드를 선택하면 음악 추천이 더 정확해져요',
                              style: GoogleFonts.lora(
                                color: const Color(0xFFA2A2A2),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (suggestedKeywords.value.isEmpty &&
                                !isLoadingKeywords.value)
                              Text(
                                '키워드를 불러오는 중...',
                                style: GoogleFonts.lora(
                                  color: const Color(0xFFBBBBBB),
                                  fontSize: 13,
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: suggestedKeywords.value.map((kw) {
                                  final isSelected =
                                      selectedKeywords.value.contains(kw);
                                  return GestureDetector(
                                    onTap: isUploading.value
                                        ? null
                                        : () {
                                            final updated = Set<String>.from(
                                                selectedKeywords.value);
                                            if (isSelected) {
                                              updated.remove(kw);
                                            } else {
                                              updated.add(kw);
                                            }
                                            selectedKeywords.value = updated;
                                          },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF333333)
                                            : const Color(0xFFF0F0F0),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF333333)
                                              : const Color(0xFFDDDDDD),
                                        ),
                                      ),
                                      child: Text(
                                        kw,
                                        style: GoogleFonts.lora(
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF555555),
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // ──── Visibility Toggle ────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SwitchListTile.adaptive(
                          value: isPublic.value,
                          onChanged: isUploading.value
                              ? null
                              : (value) {
                                  isPublic.value = value;
                                },
                          title: Text(
                            '커뮤니티에 공개하기',
                            style: GoogleFonts.lora(
                              color: const Color(0xFF3D3D3D),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            isPublic.value
                                ? '다른 사용자도 이 게시물을 볼 수 있습니다.'
                                : '나만 볼 수 있는 비공개 게시물로 저장됩니다.',
                            style: GoogleFonts.lora(
                              color: const Color(0xFF777777),
                              fontSize: 13,
                            ),
                          ),
                          activeTrackColor: const Color(0xFF333333),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ──── Develop Button ────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: isUploading.value ? null : upload,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    disabledBackgroundColor: const Color(0xFF9A9A9A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isUploading.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Develop',
                          style: GoogleFonts.lora(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Upload image to temp Storage path, then call Cloud Function for keyword suggestions.
Future<void> _fetchMoodKeywords({
  required WidgetRef ref,
  required File imageFile,
  required ValueNotifier<List<String>> suggestedKeywords,
  required ValueNotifier<Set<String>> selectedKeywords,
  required ValueNotifier<bool> isLoadingKeywords,
}) async {
  isLoadingKeywords.value = true;
  try {
    final firebaseAuth = FirebaseAuth.instance;
    final firebaseStorage = FirebaseStorage.instance;

    if (firebaseAuth.currentUser == null) {
      await firebaseAuth.signInAnonymously();
    }

    // Upload to temp path for AI analysis
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final storageRef = firebaseStorage.ref().child('temp_keywords/$tempId.jpg');
    await storageRef.putFile(imageFile);
    final downloadUrl = await storageRef.getDownloadURL();

    // Call suggestMoodKeywords Cloud Function via repository
    final repo = ref.read(cameraRepositoryProvider);
    final keywords = await repo.suggestMoodKeywords(downloadUrl);

    suggestedKeywords.value = keywords;
    // Auto-select first 3 by default
    selectedKeywords.value = keywords.take(3).toSet();

    // Clean up temp file (fire-and-forget)
    storageRef.delete().catchError((_) {});
  } catch (e) {
    debugPrint('🏷️ [MoodKeywords] Fetch failed: $e');
    // Fallback defaults
    suggestedKeywords.value = ['감성적', '따뜻한', '잔잔한', '추억', '평화로운'];
    selectedKeywords.value = {'감성적', '따뜻한', '잔잔한'};
  } finally {
    isLoadingKeywords.value = false;
  }
}

Future<double> _resolveImageAspectRatio(File imageFile) async {
  final bytes = await imageFile.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;

  if (image.height == 0) return 3 / 4;
  return image.width / image.height;
}
