import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/camera_provider.dart';

class ComposeScreen extends HookConsumerWidget {
  const ComposeScreen({super.key, required this.imageFile});

  final File imageFile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captionController = useTextEditingController();
    final isUploading = useState(false);

    final imageAspectRatioFuture = useMemoized(
      () => _resolveImageAspectRatio(imageFile),
      [imageFile.path],
    );
    final imageAspectRatio = useFuture(imageAspectRatioFuture);

    Future<void> upload() async {
      if (isUploading.value) {
        return;
      }

      isUploading.value = true;
      try {
        await ref
            .read(cameraRepositoryProvider)
            .uploadPhoto(imageFile, captionController.text.trim());

        if (!context.mounted) {
          return;
        }

        context.go('/pending');
      } catch (_) {
        if (!context.mounted) {
          return;
        }

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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Spacer(),
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

Future<double> _resolveImageAspectRatio(File imageFile) async {
  final bytes = await imageFile.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;

  if (image.height == 0) {
    return 3 / 4;
  }

  return image.width / image.height;
}
