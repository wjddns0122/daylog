import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialLoginButton extends StatelessWidget {
  final String assetPath;
  final VoidCallback onTap;
  final Color? backgroundColor;

  const SocialLoginButton({
    super.key,
    required this.assetPath,
    required this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? Colors.white,
          border: (backgroundColor == null || backgroundColor == Colors.white)
              ? Border.all(color: Colors.grey.shade300)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: SvgPicture.asset(
          assetPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
