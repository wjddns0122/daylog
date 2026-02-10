import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/social_login_button.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen for auth state changes to navigate (Will handle in main routing, but for now showing snackbars)
    ref.listen(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFD4D4D4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // Title Section (Figma: Title-Section)
                  Text(
                    '또 보네요!',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF1D1617),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '다시 돌아온 걸 환영해요!',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D1617),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Inputs matches Figma Label-Section
                  CustomTextField(
                    controller: _emailController,
                    hintText: '이메일',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: '비밀번호',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Forgot Password (Figma: Forget-Password)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {}, // TODO: Forgot Password
                      child: Text(
                        '비밀번호를 잊어버리셨나요?',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF999999),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Login Button (Figma: Button / Login)
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF757575),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                        elevation: 0,
                      ),
                      child: authState.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.login, color: Colors.white),
                                const SizedBox(width: 10),
                                Text(
                                  '로그인',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Or Divider (Figma: or)
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFF1D1617))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Or',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF1D1617),
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: Color(0xFF1D1617)),
                      ), // Use black/dark divider as per line
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Social Row (Figma: Group 10389)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SocialLoginButton(
                        assetPath:
                            'assets/images/google_logo.png', // Placeholder
                        onTap: () =>
                            ref.read(authProvider.notifier).googleSignIn(),
                      ),
                      const SizedBox(width: 20),
                      SocialLoginButton(
                        assetPath:
                            'assets/images/kakao_logo.png', // Placeholder
                        backgroundColor: const Color(
                          0xFFFEE500,
                        ), // Kakao Yellow
                        onTap: () =>
                            ref.read(authProvider.notifier).signInWithKakao(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Sign Up Link (Figma: Register-Text)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '아직 계정이 없으신가요? ',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF1D1617),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                        child: Text(
                          '계정 만들기',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(
                              0xFF1D1617,
                            ), // Or accent color? Figma says #f7f8f8 but that's white on light bg?
                            // Wait, Figma text color for "New Account" was #f7f8f8 (white?) on #d4d4d4 bg? That's low contrast.
                            // The user text #1d1617 is dark.
                            // I will use a darker color or primary color for the link.
                            // Actually, let's use a distinct color.
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
