import 'package:daylog/core/theme/app_theme.dart';
import 'package:daylog/features/auth/presentation/widgets/social_auth_button.dart';
import 'package:flutter/material.dart';

class AuthSocialSection extends StatelessWidget {
  final VoidCallback onGoogleTap;
  final VoidCallback onKakaoTap;

  const AuthSocialSection({
    super.key,
    required this.onGoogleTap,
    required this.onKakaoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Divider(color: AppTheme.authInputFill, thickness: 2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Or',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.authTextBlack),
              ),
            ),
            const Expanded(
              child: Divider(color: AppTheme.authInputFill, thickness: 2),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SocialAuthButton(
              assetPath: 'assets/svgs/google.svg',
              onTap: onGoogleTap,
            ),
            const SizedBox(width: 20),
            SocialAuthButton(
              assetPath: 'assets/svgs/kakao.svg',
              onTap: onKakaoTap,
            ),
          ],
        ),
      ],
    );
  }
}
