import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';

import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'core/config/social_login_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Kakao SDK
  KakaoSdk.init(nativeAppKey: SocialLoginConfig.kakaoNativeAppKey);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch Auth State
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Daylog',
      theme: AppTheme.lightTheme,
      home: _getHome(authState),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _getHome(AuthState state) {
    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.user != null) {
      if (state.user!.isVerified) {
        return const HomeScreen();
      } else {
        // If logged in but not verified, ideally show a specific verification screen
        // For now, valid flow is: Login checks verification. Sign Up shows dialog.
        // If we are here, it means we have a user object but not verified?
        // Our AuthNotifier sets user ONLY if verified for Login, but for SignUp it sets it?
        // Let's check AuthNotifier.signUp: "state = state.copyWith(isLoading: false, user: user);"
        // Check AuthRepository.signUp: Returns user with isVerified=false.
        // So after SignUp, we are here with isVerified=false.
        // We should show LoginScreen but maybe with a message?
        // Or show a "Please Verify Email" screen.
        // For simplicity and per plan, I'll redirect to LoginScreen implementation creates a dialog on transition.
        // But if I return HomeScreen here, user enters app.
        // I MUST RETURN LOGIN SCREEN if not verified.
        return const LoginScreen();
      }
    }

    return const LoginScreen();
  }
}
