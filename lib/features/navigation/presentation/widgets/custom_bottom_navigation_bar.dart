import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120, // Increased height for notch depth
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // 1. The Glass Bar and Notch (Layer 1 - Interactive)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ClipPath(
              clipper:
                  _NotchedBarClipper(), // Defines the shape for hit testing too
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: 10,
                    sigmaY: 10), // Reduced blur slightly for sharpness
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E4E61)
                        .withValues(alpha: 0.4), // Solid color
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildNavItem(
                            icon: Icons.add_box_outlined,
                            label: '메인',
                            index: 0),
                        _buildNavItem(
                            icon: Icons.calendar_today_outlined,
                            label: 'My Log',
                            index: 1),
                        const SizedBox(width: 60), // Space for Notch
                        _buildNavItem(
                            icon: Icons.favorite_border,
                            label: '좋아요',
                            index: 2),
                        _buildNavItem(
                            icon: Icons.person_outline,
                            label: '내 프로필',
                            index: 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Border Overlay (Layer 2 - Non-Interactive)
          Positioned(
            bottom: 30, // Must match Layer 1 EXACTLY
            left: 20,
            right: 20,
            child: IgnorePointer(
              // Critical: Let clicks pass through to Layer 1
              child: CustomPaint(
                size: const Size(double.infinity, 70),
                painter: _NotchedBarBorderPainter(),
              ),
            ),
          ),

          // 3. Floating Camera Button (Layer 3 - Interactive Top)
          Positioned(
            bottom: 65, // Adjust vertical position to sit perfectly in notch
            child: GestureDetector(
              onTap: () => context.push('/camera'),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4E4E61)
                      .withValues(alpha: 0.4), // Matches bar
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;
    final color =
        isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior:
          HitTestBehavior.opaque, // Ensures the entire column hit area works
      child: Container(
        // Add explicit width to ensure easy tapping
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Logic for Path: Concave Notch with Angular Corners
Path _getNotchedPath(Size size) {
  final path = Path();
  final w = size.width;
  final h = size.height;
  final centerX = w / 2;

  const double cornerRadius = 24.0; // Sharp corners
  const double notchRadius = 42.0; // Width of notch curve
  const double notchDepth = 35.0; // Depth of notch

  // Start Top Left
  path.moveTo(0, cornerRadius);
  path.arcToPoint(Offset(cornerRadius, 0),
      radius: const Radius.circular(cornerRadius));

  // Line to Notch Start
  path.lineTo(centerX - notchRadius - 10, 0);

  // The Notch (Smooth Concave)
  path.cubicTo(
    centerX - notchRadius, 0, // Control 1 (Start curve)
    centerX - notchRadius + 5, notchDepth, // Control 2 (Down)
    centerX, notchDepth, // End (Bottom of notch)
  );

  path.cubicTo(
    centerX + notchRadius - 5, notchDepth, // Control 1 (Up)
    centerX + notchRadius, 0, // Control 2 (End curve)
    centerX + notchRadius + 10, 0, // End (Back to top)
  );

  // Line to Top Right
  path.lineTo(w - cornerRadius, 0);
  path.arcToPoint(Offset(w, cornerRadius),
      radius: const Radius.circular(cornerRadius));

  // Right Edge
  path.lineTo(w, h - cornerRadius);
  path.arcToPoint(Offset(w - cornerRadius, h),
      radius: const Radius.circular(cornerRadius));

  // Bottom Edge
  path.lineTo(cornerRadius, h);
  path.arcToPoint(Offset(0, h - cornerRadius),
      radius: const Radius.circular(cornerRadius));

  path.close();
  return path;
}

class _NotchedBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _getNotchedPath(size);
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _NotchedBarBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _getNotchedPath(size);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0; // Thinner border

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
