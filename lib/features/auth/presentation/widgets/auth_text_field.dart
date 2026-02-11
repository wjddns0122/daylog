import 'package:daylog/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final String hintText;
  final IconData? prefixIcon;
  final bool isObscure;
  final TextEditingController? controller;
  final Widget? suffixIcon;

  const AuthTextField({
    super.key,
    required this.hintText,
    this.prefixIcon,
    this.isObscure = false,
    this.controller,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 48,
        constraints: const BoxConstraints(maxWidth: 400),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.authInputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.authInputFill),
        ),
        child: Center(
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.authTextBlack,
                ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: Theme.of(context).textTheme.bodyMedium, // Gray color
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      color: AppTheme.authTextGray,
                      size: 18,
                    )
                  : null,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ),
    );
  }
}
