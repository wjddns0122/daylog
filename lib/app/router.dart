import 'dart:io';

import 'package:daylog/features/auth/presentation/screens/login_screen.dart';
import 'package:daylog/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:daylog/features/auth/presentation/screens/signup_screen.dart';
import 'package:daylog/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:daylog/features/camera/presentation/screens/compose_screen.dart';
import 'package:daylog/features/camera/presentation/screens/camera_screen.dart'; // Added
import 'package:daylog/features/feed/presentation/screens/feed_screen.dart';
import 'package:daylog/features/feed/presentation/screens/pending_screen.dart';
import 'package:daylog/features/navigation/presentation/screens/main_scaffold.dart';
import 'package:daylog/features/notification/presentation/screens/notification_screen.dart';
import 'package:daylog/features/profile/presentation/screens/profile_screen.dart';
import 'package:daylog/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:daylog/features/profile/presentation/screens/user_posts_screen.dart';
import 'package:daylog/features/settings/presentation/screens/settings_screen.dart';
import 'package:daylog/features/settings/presentation/screens/change_password_screen.dart';
import 'package:daylog/features/calendar/presentation/screens/calendar_screen.dart'; // Added
import 'package:daylog/features/likes/presentation/screens/like_screen.dart'; // Added
import 'package:daylog/features/social/presentation/screens/follow_list_screen.dart';
import 'package:daylog/features/social/presentation/screens/follow_requests_screen.dart';
import 'package:daylog/features/social/presentation/screens/user_search_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';

part 'router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
// final _shellNavigatorKey = GlobalKey<NavigatorState>(); // Unused

@riverpod
GoRouter router(Ref ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.onDispose(refreshNotifier.dispose);

  ref.listen(authViewModelProvider, (previous, next) {
    final prevUid = previous?.valueOrNull?.uid;
    final nextUid = next.valueOrNull?.uid;
    final prevSetup = previous?.valueOrNull?.profileSetupCompleted;
    final nextSetup = next.valueOrNull?.profileSetupCompleted;

    if (prevUid != nextUid ||
        prevSetup != nextSetup ||
        previous?.isLoading != next.isLoading ||
        previous?.hasError != next.hasError) {
      refreshNotifier.bump();
    }
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authViewModelProvider);
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;

      final isLoggingIn = state.uri.toString() == '/login';
      final isSigningUp = state.uri.toString() == '/signup';
      final isProfileSetup = state.uri.toString() == '/profile-setup';
      final isProfileCompleted = user?.profileSetupCompleted ?? true;

      if (isLoading) return null;

      if (user == null && !isLoggingIn && !isSigningUp) {
        return '/login';
      }

      if (user != null && !isProfileCompleted && !isProfileSetup) {
        return '/profile-setup';
      }

      if (user != null && isProfileSetup && isProfileCompleted) {
        return '/';
      }

      if (user != null && (isLoggingIn || isSigningUp)) {
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
        path: '/profile-setup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileSetupScreen(),
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
      GoRoute(
        path: '/search-users',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UserSearchScreen(),
      ),
      GoRoute(
        path: '/follow-requests',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FollowRequestsScreen(),
      ),
      GoRoute(
        path: '/profile/followers',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const FollowListScreen(type: FollowListType.followers),
      ),
      GoRoute(
        path: '/profile/following',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const FollowListScreen(type: FollowListType.following),
      ),
      GoRoute(
        path: '/users/:uid/followers',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          return FollowListScreen(
            type: FollowListType.followers,
            userId: uid,
          );
        },
      ),
      GoRoute(
        path: '/users/:uid/following',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          return FollowListScreen(
            type: FollowListType.following,
            userId: uid,
          );
        },
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/users/:uid',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final uid = state.pathParameters['uid'];
          if (uid == null || uid.isEmpty) {
            return const ProfileScreen();
          }
          return ProfileScreen(userId: uid);
        },
      ),
      GoRoute(
        path: '/users/:uid/posts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final uid = state.pathParameters['uid'];
          if (uid == null || uid.isEmpty) {
            return const FeedScreen();
          }

          final extra = state.extra;
          String? initialPostId;
          String? title;
          if (extra is Map<String, dynamic>) {
            initialPostId = extra['initialPostId'] as String?;
            title = extra['title'] as String?;
          }

          return UserPostsScreen(
            userId: uid,
            initialPostId: initialPostId,
            title: title,
          );
        },
      ),
    ],
  );
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void bump() => notifyListeners();
}
