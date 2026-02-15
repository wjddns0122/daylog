import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../feed/presentation/providers/feed_provider.dart';
import '../providers/camera_provider.dart';

class CameraScreen extends HookConsumerWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cameraProvider);
    final pendingPost = ref.watch(currentPendingPostProvider);

    final cameraController = useState<CameraController?>(null);
    final cameraError = useState<String?>(null);
    final isInitializing = useState(true);
    final isCapturing = useState(false);
    final isShutterPressed = useState(false);
    final isFlashOn = useState(false);
    final lensDirection = useState(CameraLensDirection.back);

    Future<void> openGallery() async {
      final repository = ref.read(cameraRepositoryProvider);
      final path = await repository.pickImage();

      if (path == null || !context.mounted) {
        return;
      }

      context.push('/compose', extra: File(path));
    }

    Future<void> initializeCamera() async {
      isInitializing.value = true;
      cameraError.value = null;

      try {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          cameraError.value = 'No camera available';
          return;
        }

        CameraDescription selectedCamera = cameras.first;
        for (final cam in cameras) {
          if (cam.lensDirection == lensDirection.value) {
            selectedCamera = cam;
            break;
          }
        }

        final nextController = CameraController(
          selectedCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await nextController.initialize();
        await nextController.setFlashMode(FlashMode.off);

        if (!context.mounted) {
          await nextController.dispose();
          return;
        }

        final previousController = cameraController.value;
        cameraController.value = nextController;
        await previousController?.dispose();
        isFlashOn.value = false;
      } catch (_) {
        cameraError.value = 'Camera unavailable';
      } finally {
        if (context.mounted) {
          isInitializing.value = false;
        }
      }
    }

    useEffect(() {
      initializeCamera();

      return () {
        // Don't set cameraController.value = null here.
        // The widget is already unmounted, so updating the ValueNotifier
        // would trigger markNeedsBuild on a defunct Element.
        cameraController.value?.dispose();
      };
    }, [lensDirection.value]);

    Future<void> toggleFlash() async {
      final controller = cameraController.value;
      if (controller == null || !controller.value.isInitialized) {
        return;
      }

      try {
        final shouldTurnOn = !isFlashOn.value;
        await controller.setFlashMode(
          shouldTurnOn ? FlashMode.torch : FlashMode.off,
        );
        isFlashOn.value = shouldTurnOn;
      } catch (_) {
        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2C2822),
            content: Text(
              'Flash is not available on this camera.',
              style: GoogleFonts.lora(color: Colors.white),
            ),
          ),
        );
      }
    }

    Future<void> capturePhoto() async {
      final controller = cameraController.value;
      if (controller == null ||
          !controller.value.isInitialized ||
          isCapturing.value) {
        return;
      }

      isCapturing.value = true;

      try {
        final picture = await controller.takePicture();
        if (!context.mounted) {
          return;
        }

        context.push('/compose', extra: File(picture.path));
      } catch (_) {
        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2C2822),
            content: Text(
              'Could not capture photo. Try again.',
              style: GoogleFonts.lora(color: Colors.white),
            ),
          ),
        );
      } finally {
        isCapturing.value = false;
      }
    }

    final controller = cameraController.value;
    final bool hasPending = pendingPost.valueOrNull != null;

    return Scaffold(
      backgroundColor: const Color(0xFF181512),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF24201B),
                    Color(0xFF181512),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Column(
                    children: [
                      _TopBar(
                        hasPending: hasPending,
                        flashOn: isFlashOn.value,
                        onBack: context.pop,
                        onFlashToggle: toggleFlash,
                        onPendingTap: () => context.push('/pending'),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: _PreviewFrame(
                          isInitializing: isInitializing.value,
                          errorText: cameraError.value,
                          controller: controller,
                          onOpenGallery: openGallery,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _BottomBar(
                        isCapturing: isCapturing.value,
                        isShutterPressed: isShutterPressed.value,
                        onGalleryTap: openGallery,
                        onFlipCameraTap: () {
                          lensDirection.value =
                              lensDirection.value == CameraLensDirection.back
                                  ? CameraLensDirection.front
                                  : CameraLensDirection.back;
                        },
                        onShutterTapDown: () => isShutterPressed.value = true,
                        onShutterTapCancel: () =>
                            isShutterPressed.value = false,
                        onShutterTap: () async {
                          await capturePhoto();
                          isShutterPressed.value = false;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (state.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.hasPending,
    required this.flashOn,
    required this.onBack,
    required this.onFlashToggle,
    required this.onPendingTap,
  });

  final bool hasPending;
  final bool flashOn;
  final VoidCallback onBack;
  final VoidCallback onFlashToggle;
  final VoidCallback onPendingTap;

  @override
  Widget build(BuildContext context) {
    const iconColor = Color(0xFFE8E0D2);

    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.close_rounded,
          onTap: onBack,
          iconColor: iconColor,
        ),
        Expanded(
          child: Center(
            child: Text(
              'Slow Camera',
              style: GoogleFonts.lora(
                color: const Color(0xFFE7DFD1),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        _CircleIconButton(
          icon: flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          onTap: onFlashToggle,
          iconColor: iconColor,
        ),
        const SizedBox(width: 8),
        Stack(
          children: [
            _CircleIconButton(
              icon: Icons.hourglass_empty_rounded,
              onTap: onPendingTap,
              iconColor: hasPending
                  ? const Color(0xFFF0C87A)
                  : const Color(0xFFB8AA95),
            ),
            if (hasPending)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD88D3F),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({
    required this.isInitializing,
    required this.errorText,
    required this.controller,
    required this.onOpenGallery,
  });

  final bool isInitializing;
  final String? errorText;
  final CameraController? controller;
  final VoidCallback onOpenGallery;

  @override
  Widget build(BuildContext context) {
    final hasCamera = controller != null && controller!.value.isInitialized;

    Widget content;
    if (isInitializing) {
      content = const Center(child: CircularProgressIndicator());
    } else if (!hasCamera) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              errorText ?? 'Camera is unavailable right now.',
              style: GoogleFonts.lora(
                color: const Color(0xFFE6DDCF),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onOpenGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                'Pick from gallery',
                style: GoogleFonts.lora(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEBDCC2),
              ),
            ),
          ],
        ),
      );
    } else {
      final previewSize = controller!.value.previewSize;
      final preview = previewSize == null
          ? CameraPreview(controller!)
          : SizedBox(
              width: previewSize.height,
              height: previewSize.width,
              child: CameraPreview(controller!),
            );

      content = LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: preview,
                  ),
                ),
              ),
              const _ViewfinderOverlay(),
            ],
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF5B5348), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: ColoredBox(
          color: const Color(0xFF11100E),
          child: content,
        ),
      ),
    );
  }
}

class _ViewfinderOverlay extends StatelessWidget {
  const _ViewfinderOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0x99E8DCC8),
                  width: 1,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.05,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.28),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x66E8DCC8)
      ..strokeWidth = 0.8;

    final oneThirdW = size.width / 3;
    final twoThirdW = oneThirdW * 2;
    final oneThirdH = size.height / 3;
    final twoThirdH = oneThirdH * 2;

    canvas.drawLine(
        Offset(oneThirdW, 0), Offset(oneThirdW, size.height), paint);
    canvas.drawLine(
        Offset(twoThirdW, 0), Offset(twoThirdW, size.height), paint);
    canvas.drawLine(Offset(0, oneThirdH), Offset(size.width, oneThirdH), paint);
    canvas.drawLine(Offset(0, twoThirdH), Offset(size.width, twoThirdH), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isCapturing,
    required this.isShutterPressed,
    required this.onGalleryTap,
    required this.onFlipCameraTap,
    required this.onShutterTapDown,
    required this.onShutterTapCancel,
    required this.onShutterTap,
  });

  final bool isCapturing;
  final bool isShutterPressed;
  final VoidCallback onGalleryTap;
  final VoidCallback onFlipCameraTap;
  final VoidCallback onShutterTapDown;
  final VoidCallback onShutterTapCancel;
  final VoidCallback onShutterTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        child: Row(
          children: [
            _CircleIconButton(
              icon: Icons.photo_library_outlined,
              onTap: onGalleryTap,
              iconColor: const Color(0xFFD8CCB8),
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTapDown: (_) => onShutterTapDown(),
                  onTapCancel: onShutterTapCancel,
                  onTapUp: (_) => onShutterTapCancel(),
                  onTap: isCapturing ? null : onShutterTap,
                  child: AnimatedScale(
                    scale: isShutterPressed ? 0.94 : 1,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF5EFE4),
                        border: Border.all(
                          color: const Color(0xFFDED3C2),
                          width: 6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF000000).withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: isCapturing
                          ? const Padding(
                              padding: EdgeInsets.all(26),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Color(0xFF3A332B),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            _CircleIconButton(
              icon: Icons.flip_camera_ios_outlined,
              onTap: onFlipCameraTap,
              iconColor: const Color(0xFFD8CCB8),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x2AE6DCCB),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}
