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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요.')),
      );
      return;
    }

    await ref.read(authViewModelProvider.notifier).login(
          email: email,
          password: password,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: ${next.error}')),
        );
      } else if (next.hasValue && next.value != null) {
        context.go('/');
      }
    });

    final isLoading = ref.watch(authViewModelProvider).isLoading;

    return AuthScaffold(
      children: [
        const Spacer(flex: 1),
        const AuthHeader(
          title: '또 보네요!',
          subtitle: '다시 돌아온 걸 환영해요!',
        ),
        const Spacer(flex: 1),
        AuthTextField(
          controller: _emailController,
          hintText: '이메일',
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
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Center(
            child: TextButton(
              onPressed: () {},
              child: Text(
                '비밀번호를 잊어버리셨나요?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.authInputFill,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.authInputFill,
                      fontSize: 12,
                    ),
              ),
            ),
          ),
        ),
        const Spacer(flex: 1),
        AuthButton(
          text: '로그인',
          isLoading: isLoading,
          onTap: _onLogin,
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
            onTap: () => context.push('/signup'),
            child: RichText(
              text: TextSpan(
                text: '아직 계정이 없으신가요? ',
                style: Theme.of(context).textTheme.titleMedium,
                children: [
                  TextSpan(
                    text: '계정 만들기',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppTheme.authInputFill),
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
