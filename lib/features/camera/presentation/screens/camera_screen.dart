import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/camera_provider.dart';
import '../../../feed/presentation/screens/pending_screen.dart';

class CameraScreen extends HookConsumerWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the new cameraProvider which returns CameraState
    final state = ref.watch(cameraProvider);
    final captionController = useTextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daylog Gallery Mode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.hourglass_empty),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PendingScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                if (state.imagePath != null)
                  Image.file(
                    File(state.imagePath!),
                    height: 400,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                else
                  const SizedBox(
                    height: 400,
                    child: Center(child: Text('No image selected')),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: captionController,
                              decoration: const InputDecoration(
                                labelText: 'Write a caption...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                          ),
                          if (state.imagePath != null) ...[
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              onPressed: state.isGeneratingCaption
                                  ? null
                                  : () async {
                                      final caption = await ref
                                          .read(cameraProvider.notifier)
                                          .generateCaption();
                                      if (caption != null) {
                                        captionController.text = caption;
                                      }
                                    },
                              icon: state.isGeneratingCaption
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.auto_awesome),
                              tooltip: 'AI Write',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
          if (state.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'pick',
            onPressed: () async {
              final repository = ref.read(cameraRepositoryProvider);
              final path = await repository.pickImage();
              if (path != null) {
                ref.read(cameraProvider.notifier).setImage(path);
              }
            },
            child: const Icon(Icons.photo_library),
          ),
          const SizedBox(height: 16),
          if (state.imagePath != null)
            FloatingActionButton(
              heroTag: 'upload',
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              onPressed: () async {
                await ref
                    .read(cameraProvider.notifier)
                    .uploadCurrentPhoto(captionController.text);
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const PendingScreen()),
                  );
                }
              },
              child: const Icon(Icons.cloud_upload),
            ),
        ],
      ),
    );
  }
}
