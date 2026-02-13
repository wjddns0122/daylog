// Verified: Fonts (Lora), Animation (Page Flip), Glassmorphism applied.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:daylog/features/feed/presentation/providers/feed_provider.dart';

class PendingScreen extends ConsumerStatefulWidget {
  const PendingScreen({super.key});

  @override
  ConsumerState<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends ConsumerState<PendingScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });

    // Page turning animation (Subtle flip effect)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _flipAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "Ready to release!";
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return "$hours hours and $minutes minutes left";
  }

  double _calculateProgress(DateTime releaseTime) {
    const totalDuration = Duration(hours: 6);
    final now = DateTime.now();
    final remaining = releaseTime.difference(now);

    if (remaining.isNegative) return 1.0;

    final elapsed = totalDuration - remaining;
    double progress = elapsed.inSeconds / totalDuration.inSeconds;
    return progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final pendingPostAsync = ref.watch(currentPendingPostProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFD4D4D4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF474747)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Image.asset(
          'assets/images/logo_header.png',
          height: 30,
        ),
        centerTitle: true,
      ),
      body: pendingPostAsync.when(
        data: (post) {
          if (post == null) {
            return const Center(child: Text("No pending posts."));
          }
          final releaseTime =
              post.releaseTime ?? DateTime.now().add(const Duration(hours: 6));
          final remaining = releaseTime.difference(DateTime.now());

          return Column(
            children: [
              const SizedBox(height: 50),
              Text(
                "Developing....",
                style: GoogleFonts.lora(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _formatDuration(remaining),
                style: GoogleFonts.lora(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF7A7A7A),
                ),
              ),
              const SizedBox(height: 50),
              // Animated Card
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // Perspective
                          ..rotateY(_flipAnimation.value),
                        alignment: Alignment.center,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 300,
                      height: 340,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6E6E6),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.15),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Divider(
                            color: Color(0xFFD1D1D1),
                            thickness: 1,
                            height: 1,
                          ),
                          // Split-Flap Animation Widget
                          const _SplitFlapIcon(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Glassmorphism Progress Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28.0, vertical: 50),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      height: 20,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(22),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _calculateProgress(releaseTime),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF232323),
                                    Color(0xFF7A7A7A)
                                  ],
                                  stops: [0.0, 1.0],
                                ),
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}

class _SplitFlapIcon extends StatefulWidget {
  const _SplitFlapIcon();

  @override
  State<_SplitFlapIcon> createState() => _SplitFlapIconState();
}

class _SplitFlapIconState extends State<_SplitFlapIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 2 seconds per cycle
    )..repeat();

    // 0 -> pi (180 degrees) flip
    _animation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: math.pi),
          weight: 20), // Top flap falls down
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 80), // Wait
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 60.0;
    const Color cardColor = Color(0xFFE6E6E6);

    // The content is the SVG icon
    final Widget icon = SvgPicture.asset(
      'assets/svgs/pending.svg',
      width: size,
      height: size,
      colorFilter: const ColorFilter.mode(
        Color(0xFF474747),
        BlendMode.srcIn,
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value;
          final isTopHalfFalling = angle < (math.pi / 2);
          // Shadow opacity peaks at 90 degrees (pi/2)
          final shadowOpacity = (math.sin(angle).abs() * 0.3).clamp(0.0, 1.0);

          return Stack(
            alignment: Alignment.center,
            children: [
              // 1. Static Bottom Layer (Top Half Hidden)
              ClipRect(
                clipper: BottomHalfClipper(),
                child: icon,
              ),

              // 2. Static Top Layer (Hidden behind animation, revealed if animation exposes it)
              ClipRect(
                clipper: TopHalfClipper(),
                child: Container(
                  width: size,
                  height: size,
                  color: cardColor,
                  child: icon,
                ),
              ),

              // 3. The Flap (Whole Icon clipped to Top or Bottom)
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective
                  ..rotateX(angle),
                alignment: Alignment
                    .center, // Rotate around center since we are using full size widgets with clippers
                child: isTopHalfFalling
                    ?
                    // Front of Flap: Top Half
                    ClipRect(
                        clipper: TopHalfClipper(),
                        child: Container(
                          color: cardColor,
                          child: Stack(
                            children: [
                              icon,
                              // Shadow Overlay (Darker at bottom/hinge)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(shadowOpacity),
                                      Colors.transparent,
                                    ],
                                    stops: const [
                                      0.0,
                                      1.0
                                    ], // Fades out upwards
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    :
                    // Back of Flap: Bottom Half (Inverted)
                    Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationX(math.pi),
                        child: ClipRect(
                          clipper: BottomHalfClipper(),
                          child: Container(
                            color: cardColor,
                            child: Stack(
                              children: [
                                icon,
                                // Shadow Overlay (Darker at top/hinge - visual bottom here)
                                // Since this is flipped 180 (pi), the "bottom" of this widget is the top visually?
                                // Let's think: We rotateX(pi).
                                // Original Bottom -> Visual Top (Hinge).
                                // So we want shadow at Original Bottom (Alignment.bottomCenter)?
                                // Wait, rotateX(pi):
                                // Top(0) -> Bottom.
                                // Bottom(h) -> Top.
                                // So Hinge is at Bottom of the widget (before flip).
                                // After flip, Hinge is at Top.
                                // So shadow should be at Bottom of the original widget (which becomes Top/Hinge).
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment
                                          .topCenter, // The hinge side visually?
                                      // Actually, let's test. If we want shadow at hinge:
                                      // Hinge acts as pivot.
                                      // For Bottom Half (Back), pivot is Top.
                                      // Wait, we pivot around CENTER of the whole icon.
                                      // Hinge is Center Line.
                                      // For Bottom Half, Center Line is Top Edge.
                                      // So Shadow should be at Top Edge.
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(shadowOpacity),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class TopHalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width, size.height / 2);
  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

class BottomHalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, size.height / 2, size.width, size.height);
  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}
