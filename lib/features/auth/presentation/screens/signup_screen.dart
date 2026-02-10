import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/social_login_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _agreedToTerms = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signup() {
    if (_formKey.currentState!.validate()) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('약관에 동의해주세요.')));
        return;
      }

      ref
          .read(authProvider.notifier)
          .signUp(
            email: _emailController.text,
            password: _passwordController.text,
            name: _nameController.text,
            nickname: _nicknameController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen for errors
    ref.listen(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
      // If user is created (and verify email sent), show dialog
      if (next.user != null &&
          previous?.user == null &&
          !next.user!.isVerified) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('이메일 확인'),
            content: const Text('인증 메일이 발송되었습니다. 이메일을 확인해주세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to login
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
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
                  const SizedBox(height: 40),
                  // Title Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '어서와요!',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF1D1617),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '계정을 만들어 볼까요?',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1D1617),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Inputs matches Figma Label-Section
                  CustomTextField(
                    controller: _nameController,
                    hintText: '이름',
                    prefixIcon: Icons.person_outline,
                    validator: (value) => value!.isEmpty ? '이름을 입력해주세요' : null,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _nicknameController,
                    hintText: '닉네임',
                    prefixIcon:
                        Icons.alternate_email, // Iconly/Light/Profile analog
                    validator: (value) => value!.isEmpty ? '닉네임을 입력해주세요' : null,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _emailController,
                    hintText: '이메일',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.isEmpty ? '이메일을 입력해주세요' : null,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: '비밀번호',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) =>
                        value!.length < 6 ? '비밀번호는 6자 이상이어야 합니다' : null,
                  ),
                  const SizedBox(height: 20),

                  // Privacy Policy (Figma: Privacy-Policy)
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (value) =>
                              setState(() => _agreedToTerms = value!),
                          fillColor: WidgetStateProperty.resolveWith((states) {
                            if (!states.contains(WidgetState.selected)) {
                              return const Color(0xFFD4D4D4);
                            }
                            return const Color(0xFF4E4E4E);
                          }),
                          side: const BorderSide(color: Color(0xFFADA4A5)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '개인정보 보호정책 및 이용약관 동의',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF484848),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Sign Up Button (Figma: Button / Large / Register)
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF757575),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                        elevation: 0,
                      ),
                      child: authState.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              '회원가입',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Or Divider (Reuse from Login)
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: Color(0xFF1D1617)),
                      ), // Use black/dark divider
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
                      const Expanded(child: Divider(color: Color(0xFF1D1617))),
                    ],
                  ),
                  const SizedBox(height: 20),

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
                  const SizedBox(height: 20),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '이미 계정이 있으신가요? ',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF1D1617),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Go back to Login
                        },
                        child: Text(
                          '로그인',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(
                              0xFF1D1617,
                            ), // Using Black for contrast
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
