import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialAuthButton extends StatelessWidget {
  final String assetPath;
  final VoidCallback onTap;

  const SocialAuthButton({
    super.key,
    required this.assetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              Colors.white, // Default to white, can be parameterized if needed
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            assetPath,
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }
}
