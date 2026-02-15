import 'dart:async';
import 'dart:io';

import 'package:daylog/features/camera/domain/repositories/camera_repository.dart';
import 'package:daylog/features/camera/presentation/providers/camera_provider.dart';
import 'package:daylog/features/camera/presentation/screens/compose_screen.dart';
import 'package:daylog/features/feed/domain/entities/feed_entity.dart';
import 'package:daylog/features/feed/domain/repositories/feed_repository.dart';
import 'package:daylog/features/feed/presentation/providers/feed_provider.dart';
import 'package:daylog/features/feed/presentation/screens/feed_screen.dart';
import 'package:daylog/features/feed/presentation/screens/pending_screen.dart';
import 'package:daylog/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full user journey works end-to-end with mocked backend', (
    WidgetTester tester,
  ) async {
    debugPrint('STEP 0: setup');
    final imageFilePath =
        '${Directory.current.path}/assets/images/logo_header.png';
    debugPrint('STEP 0.1: fixture image path ready');

    final feedRepository = _FakeFeedRepository();
    debugPrint('STEP 0.2: fake feed ready');
    addTearDown(feedRepository.dispose);
    final cameraRepository = _FakeCameraRepository(
      imagePath: imageFilePath,
      onUpload: feedRepository.uploadPendingPost,
    );
    debugPrint('STEP 0.3: fake camera ready');

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const FeedScreen()),
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
        GoRoute(path: '/pending', builder: (_, __) => const PendingScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(
          path: '/login',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Login Screen'))),
        ),
      ],
    );
    debugPrint('STEP 0.4: router ready');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('user_01'),
          feedRepositoryProvider.overrideWithValue(feedRepository),
          cameraRepositoryProvider.overrideWithValue(cameraRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    debugPrint('STEP 1: app pumped');

    await _pumpUntilFound(tester, find.byType(FeedScreen));
    debugPrint('STEP 2: feed visible');

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(const Duration(milliseconds: 300));

    await _pumpUntilFound(tester, find.text('Pick from gallery'));
    debugPrint('STEP 3: camera fallback visible');
    await tester.tap(find.text('Pick from gallery'));
    await tester.pump(const Duration(milliseconds: 300));

    await _pumpUntilFound(tester, find.text('Compose'));
    debugPrint('STEP 4: compose visible');
    await tester.enterText(find.byType(TextField), 'A calm morning memory');
    await tester.tap(find.text('Develop'));
    await tester.pump(const Duration(milliseconds: 600));

    await _pumpUntilFound(tester, find.text('Developing....'));
    debugPrint('STEP 5: pending visible');

    feedRepository.releaseLatestPost();
    await tester.pump(const Duration(milliseconds: 100));
    await _pumpUntilFound(tester, find.text('Developed Memory'));
    debugPrint('STEP 6: result visible');

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump(const Duration(milliseconds: 400));

    if (find.byType(FeedScreen).evaluate().isEmpty) {
      router.go('/');
      await tester.pump(const Duration(milliseconds: 200));
      await _pumpUntilFound(tester, find.byType(FeedScreen));
    }

    await _pumpUntilFound(tester, find.text('A calm morning memory'));
    debugPrint('STEP 7: feed contains new post');

    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pump(const Duration(milliseconds: 800));
    await _pumpUntilFound(tester, find.text('Today_log'));
    debugPrint('STEP 8: calendar visible');

    final calendarThumbnailCount = find.byType(Image).evaluate().where((e) {
      final widget = e.widget;
      return widget is Image && widget.image is NetworkImage;
    }).length;
    expect(
      calendarThumbnailCount,
      greaterThan(0),
      reason:
          'Expected calendar to show uploaded post thumbnail, but no thumbnail appeared.',
    );

    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pump(const Duration(milliseconds: 500));
    await _pumpUntilFound(tester, find.text('Profile'));
    debugPrint('STEP 9: profile visible');

    expect(
      find.text('Settings'),
      findsOneWidget,
      reason:
          'Expected a Profile -> Settings navigation entry, but none was found.',
    );
    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 400));

    await _pumpUntilFound(tester, find.text('Settings'));
    debugPrint('STEP 10: settings visible');
    await tester.tap(find.text('Logout'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Login Screen'), findsOneWidget);
    debugPrint('STEP 11: logout complete');
    await tester.pumpWidget(const SizedBox.shrink());
    debugPrint('STEP 12: disposed');
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 8),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  for (var i = 0; i < maxTicks; i++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(step);
  }
  expect(finder, findsWidgets);
}

class _FakeCameraRepository implements CameraRepository {
  _FakeCameraRepository({required this.imagePath, required this.onUpload});

  final String imagePath;
  final Future<void> Function(String caption) onUpload;

  @override
  Future<String?> pickImage() async => imagePath;

  @override
  Future<void> uploadPhoto(File file, String content, String visibility) async {
    await onUpload(content);
  }
}

class _FakeFeedRepository implements FeedRepository {
  final _feedController = StreamController<List<FeedEntity>>.broadcast();
  final _latestController = StreamController<FeedEntity?>.broadcast();
  final List<FeedEntity> _posts = [];

  _FakeFeedRepository() {
    _feedController.add(const []);
    _latestController.add(null);
  }

  void dispose() {
    _feedController.close();
    _latestController.close();
  }

  Future<void> uploadPendingPost(String caption) async {
    final now = DateTime.now();
    final pendingPost = FeedEntity(
      id: 'post_01',
      userId: 'user_01',
      url: 'https://example.com/daylog.png',
      content: caption,
      timestamp: now,
      status: 'PENDING',
      releaseTime: now.add(const Duration(hours: 6)),
      likedBy: const [],
    );

    _posts
      ..clear()
      ..add(pendingPost);
    _feedController.add(List<FeedEntity>.from(_posts));
    _latestController.add(pendingPost);
  }

  void releaseLatestPost() {
    if (_posts.isEmpty) {
      return;
    }
    final latest = _posts.first;
    final releasedPost = FeedEntity(
      id: latest.id,
      userId: latest.userId,
      url: latest.url,
      content: latest.content,
      timestamp: latest.timestamp,
      status: 'RELEASED',
      releaseTime: latest.releaseTime,
      likedBy: latest.likedBy,
      aiCuration: 'Mocked release complete.',
      musicTitle: 'Mock Track',
      musicUrl: 'https://www.youtube.com/watch?v=mocked',
    );

    _posts
      ..clear()
      ..add(releasedPost);
    _feedController.add(List<FeedEntity>.from(_posts));
    _latestController.add(releasedPost);
  }

  @override
  Stream<List<FeedEntity>> getFeedStream() => _feedController.stream;

  @override
  Stream<List<FeedEntity>> getMyFeedStream(String userId) =>
      _feedController.stream;

  @override
  Stream<List<FeedEntity>> getLikedFeedStream(String userId) =>
      _feedController.stream;

  @override
  Stream<FeedEntity?> getLatestPostForUser(String userId) =>
      _latestController.stream;

  @override
  Future<List<FeedEntity>> getUserPostsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _posts
        .where((post) =>
            post.userId == userId &&
            post.status == 'RELEASED' &&
            !post.timestamp.isBefore(startDate) &&
            post.timestamp.isBefore(endDate))
        .toList(growable: false);
  }

  @override
  Stream<FeedEntity?> getMyPendingPost(String userId) =>
      _latestController.stream
          .map((post) => post?.status == 'PENDING' ? post : null);

  @override
  Future<void> deletePost(String postId, String imageUrl) async {}

  @override
  Future<void> toggleLike(String postId, String userId, bool isLiked) async {}

  @override
  Future<void> updatePostCaption(String postId, String newCaption) async {
    if (_posts.isEmpty) {
      return;
    }
    final current = _posts.first;
    final updated = FeedEntity(
      id: current.id,
      userId: current.userId,
      url: current.url,
      content: newCaption,
      timestamp: current.timestamp,
      status: current.status,
      releaseTime: current.releaseTime,
      likedBy: current.likedBy,
      aiCuration: current.aiCuration,
      musicTitle: current.musicTitle,
      musicUrl: current.musicUrl,
    );

    _posts
      ..clear()
      ..add(updated);
    _feedController.add(List<FeedEntity>.from(_posts));
    _latestController.add(updated);
  }
}
