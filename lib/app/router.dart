import 'dart:io';

import 'package:daylog/features/auth/presentation/screens/login_screen.dart';
import 'package:daylog/features/auth/presentation/screens/signup_screen.dart';
import 'package:daylog/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:daylog/features/camera/presentation/screens/compose_screen.dart';
import 'package:daylog/features/feed/presentation/screens/feed_screen.dart';
import 'package:daylog/features/feed/presentation/screens/pending_screen.dart';
import 'package:daylog/features/notification/presentation/screens/notification_screen.dart';
import 'package:daylog/features/profile/presentation/screens/profile_screen.dart';
import 'package:daylog/features/settings/presentation/screens/settings_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;

      final isLoggingIn = state.uri.toString() == '/login';
      final isSigningUp = state.uri.toString() == '/signup';

      if (isLoading) return null;

      if (user == null && !isLoggingIn && !isSigningUp) {
        return '/login';
      }

      if (user != null && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/compose',
        builder: (context, state) {
          final imageFile = state.extra;
          if (imageFile is! File) {
            return const FeedScreen();
          }

          return ComposeScreen(imageFile: imageFile);
        },
      ),
      GoRoute(
        path: '/pending',
        builder: (context, state) => const PendingScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
    ],
  );
}
