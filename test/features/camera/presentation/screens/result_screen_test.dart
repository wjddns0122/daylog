import 'package:daylog/features/camera/presentation/screens/result_screen.dart';
import 'package:daylog/features/feed/domain/entities/feed_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ResultScreen renders released content and golden', (
    WidgetTester tester,
  ) async {
    final openedUris = <Uri>[];

    final post = FeedEntity(
      id: 'post_01',
      url: '',
      content: '오늘의 빛은 천천히 내려앉아 내 마음을 다독여 주었다.',
      timestamp: DateTime(2026, 2, 13, 22, 0),
      status: 'RELEASED',
      aiCuration: '오늘의 빛은 천천히 내려앉아 내 마음을 다독여 주었다.',
      musicTitle: 'Nujabes - Luv(sic) Part 3',
      musicUrl: 'https://www.youtube.com/watch?v=8iP3J8jFYdM',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resultScreenLaunchUrlProvider.overrideWithValue((uri) async {
            openedUris.add(uri);
            return true;
          }),
        ],
        child: MaterialApp(
          home: ResultScreen(post: post),
        ),
      ),
    );

    expect(find.text('Developed Memory'), findsOneWidget);
    expect(find.text('AI Curation'), findsOneWidget);
    expect(find.text('Nujabes - Luv(sic) Part 3'), findsOneWidget);
    expect(find.text('Share to Instagram Stories'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Open YouTube'));
    await tester.tap(find.byTooltip('Open YouTube'));
    await tester.pump();
    expect(openedUris, hasLength(1));
    expect(openedUris.first.toString(), post.musicUrl);

    await expectLater(
      find.byType(ResultScreen),
      matchesGoldenFile('goldens/result_screen.png'),
    );
  });
}
