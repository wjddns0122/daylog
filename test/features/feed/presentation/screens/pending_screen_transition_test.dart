import 'dart:async';

import 'package:daylog/features/feed/domain/entities/feed_entity.dart';
import 'package:daylog/features/feed/domain/repositories/feed_repository.dart';
import 'package:daylog/features/feed/presentation/providers/feed_provider.dart';
import 'package:daylog/features/feed/presentation/screens/pending_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PendingScreen navigates to ResultScreen when status is released',
      (
    WidgetTester tester,
  ) async {
    final latestPostController = StreamController<FeedEntity?>.broadcast();
    addTearDown(latestPostController.close);

    final repository = _FakeFeedRepository(
      latestPostStream: latestPostController.stream,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('user_01'),
          feedRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: PendingScreen()),
      ),
    );

    latestPostController.add(_buildPost(status: 'PENDING'));
    await tester.pump();

    expect(find.text('Developing....'), findsOneWidget);

    latestPostController.add(
      _buildPost(
        status: 'RELEASED',
        aiCuration: 'Released curation text',
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Developed Memory'), findsOneWidget);
    expect(find.text('Released curation text'), findsOneWidget);
  });
}

FeedEntity _buildPost({
  required String status,
  String? aiCuration,
}) {
  return FeedEntity(
    id: 'post_01',
    url: '',
    content: 'Post caption',
    timestamp: DateTime(2026, 2, 13, 12),
    userId: 'user_01',
    status: status,
    releaseTime: DateTime(2026, 2, 13, 18),
    aiCuration: aiCuration,
    musicTitle: 'Track',
    musicUrl: 'https://www.youtube.com/watch?v=abc',
  );
}

class _FakeFeedRepository implements FeedRepository {
  _FakeFeedRepository({required this.latestPostStream});

  final Stream<FeedEntity?> latestPostStream;

  @override
  Stream<List<FeedEntity>> getFeedStream() => Stream.value(const []);

  @override
  Stream<List<FeedEntity>> getLikedFeedStream(String userId) =>
      Stream.value(const []);

  @override
  Stream<FeedEntity?> getLatestPostForUser(String userId) => latestPostStream;

  @override
  Stream<FeedEntity?> getMyPendingPost(String userId) =>
      latestPostStream.map((post) => post?.status == 'PENDING' ? post : null);

  @override
  Future<void> deletePost(String postId, String imageUrl) async {}

  @override
  Future<void> toggleLike(String postId, String userId, bool isLiked) async {}
}
