import 'package:daylog/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:daylog/features/auth/presentation/widgets/social_login_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: ${next.error}')),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Logo / Branding
            Center(
              child: Text(
                'DAYLOG',
                style: GoogleFonts.outfit(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                  color: Colors.black,
                ),
              ),
            ),
            const Spacer(),
            // Social Login Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Kakao
                  SocialLoginButton(
                    assetPath: 'assets/svgs/kakao.svg',
                    backgroundColor: const Color(0xFFFEE500),
                    onTap: () async {
                      try {
                        await ref
                            .read(authViewModelProvider.notifier)
                            .loginWithKakao();
                        if (context.mounted) {
                          final state = ref.read(authViewModelProvider);
                          if (!state.hasError) {
                            context.go('/');
                          }
                        }
                      } catch (e) {
                        // Error handled by ViewModel state usually, but strictly:
                      }
                    },
                  ),
                  const SizedBox(width: 24),
                  // Google
                  SocialLoginButton(
                    assetPath: 'assets/svgs/google.svg',
                    onTap: () {
                      ref
                          .read(authViewModelProvider.notifier)
                          .loginWithGoogle();
                    },
                  ),
                  // const SizedBox(width: 24),
                  // Apple (Placeholder for now)
                  // SocialLoginButton(
                  //   assetPath: 'assets/svgs/apple_icon.svg',
                  //   backgroundColor: Colors.black,
                  //   onTap: () {
                  //     // TODO: Implement Apple Login
                  //   },
                  //),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
