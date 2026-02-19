import 'dart:io';

import 'package:daylog/features/auth/presentation/screens/login_screen.dart';
import 'package:daylog/features/auth/presentation/screens/signup_screen.dart';
import 'package:daylog/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:daylog/features/camera/presentation/screens/compose_screen.dart';
import 'package:daylog/features/camera/presentation/screens/camera_screen.dart'; // Added
import 'package:daylog/features/feed/presentation/screens/feed_screen.dart';
import 'package:daylog/features/feed/presentation/screens/pending_screen.dart';
import 'package:daylog/features/navigation/presentation/screens/main_scaffold.dart';
import 'package:daylog/features/notification/presentation/screens/notification_screen.dart';
import 'package:daylog/features/profile/presentation/screens/profile_screen.dart';
import 'package:daylog/features/settings/presentation/screens/settings_screen.dart';
import 'package:daylog/features/settings/presentation/screens/change_password_screen.dart';
import 'package:daylog/features/calendar/presentation/screens/calendar_screen.dart'; // Added
import 'package:daylog/features/likes/presentation/screens/like_screen.dart'; // Added
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';

part 'router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
// final _shellNavigatorKey = GlobalKey<NavigatorState>(); // Unused

@riverpod
GoRouter router(Ref ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/likes',
                builder: (context, state) => const LikeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
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
        parentNavigatorKey: _rootNavigatorKey, // Fullscreen
        builder: (context, state) {
          final imageFile = state.extra;
          if (imageFile is! File) {
            return const FeedScreen(); // Fallback
          }

          return ComposeScreen(imageFile: imageFile);
        },
      ),
      GoRoute(
        path: '/camera',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/pending',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PendingScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/change-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationScreen(),
      ),
    ],
  );
}
