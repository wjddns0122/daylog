import 'package:daylog/core/theme/app_theme.dart';
import 'package:daylog/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:daylog/features/auth/presentation/widgets/auth_button.dart';
import 'package:daylog/features/auth/presentation/widgets/auth_header.dart';
import 'package:daylog/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:daylog/features/auth/presentation/widgets/auth_social_section.dart';
import 'package:daylog/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isAgreed = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _onSignUp() async {
    final lastName = _lastNameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final nickname = _nicknameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = '$lastName $firstName'.trim();

    if (lastName.isEmpty ||
        firstName.isEmpty ||
        nickname.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해주세요.')),
      );
      return;
    }

    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약관에 동의해주세요.')),
      );
      return;
    }

    await ref.read(authViewModelProvider.notifier).signUp(
          email: email,
          password: password,
          name: name,
          nickname: nickname,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 실패: ${next.error}')),
        );
      }
      // Navigation is handled by router based on auth state
    });

    final isLoading = ref.watch(authViewModelProvider).isLoading;

    return AuthScaffold(
      showBackButton: true,
      children: [
        const SizedBox(height: 48), // Padding for the back button space
        const AuthHeader(
          title: '어서와요!',
          subtitle: '계정을 만들어 볼까요?',
        ),
        const Spacer(flex: 1),
        AuthTextField(
          controller: _lastNameController,
          hintText: '성',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _firstNameController,
          hintText: '이름',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _nicknameController,
          hintText: '닉네임',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _emailController,
          hintText: '이메일 주소',
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _passwordController,
          hintText: '비밀번호',
          isObscure: !_isPasswordVisible,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppTheme.authTextGray,
              size: 18,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Row(
              children: [
                Checkbox(
                  value: _isAgreed,
                  onChanged: (v) {
                    setState(() {
                      _isAgreed = v ?? false;
                    });
                  },
                  activeColor: AppTheme.authButton,
                ),
                Expanded(
                  child: Text(
                    '개인정보 보호정책 및 이용약관 동의',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(flex: 1),
        AuthButton(
          text: '회원가입',
          isLoading: isLoading,
          onTap: _onSignUp,
        ),
        const Spacer(flex: 1),
        AuthSocialSection(
          onGoogleTap: () =>
              ref.read(authViewModelProvider.notifier).loginWithGoogle(),
          onKakaoTap: () =>
              ref.read(authViewModelProvider.notifier).loginWithKakao(),
        ),
        const Spacer(flex: 1),
        Center(
          child: GestureDetector(
            onTap: () => context.pop(),
            child: RichText(
              text: TextSpan(
                text: '이미 계정이 있으신가요? ',
                style: Theme.of(context).textTheme.titleMedium,
                children: [
                  TextSpan(
                    text: '로그인',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.authInputFill,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
