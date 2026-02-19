import 'package:daylog/features/notification/domain/entities/notification_entity.dart';
import 'package:daylog/features/notification/domain/repositories/notification_repository.dart';
import 'package:daylog/features/notification/presentation/providers/notification_provider.dart';
import 'package:daylog/features/notification/presentation/screens/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('follow request notification navigates to follow request route', (
    tester,
  ) async {
    final repository = _FakeNotificationRepository(
      notifications: [
        NotificationEntity(
          id: 'n1',
          title: '새 팔로우 요청',
          message: '새로운 사용자가 팔로우를 요청했습니다.',
          type: NotificationType.followRequest,
          createdAt: DateTime(2026, 2, 20, 10),
          payload: const {'requestId': 'req_01'},
        ),
      ],
    );

    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationScreen(),
        ),
        GoRoute(
          path: '/follow-requests',
          builder: (_, __) => const Scaffold(
              body: Center(child: Text('Follow Requests Route'))),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('새 팔로우 요청'), findsOneWidget);
    expect(find.byIcon(Icons.person_add_alt_1_rounded), findsOneWidget);

    await tester.tap(find.text('새 팔로우 요청'));
    await _pumpUntilFound(tester, find.text('Follow Requests Route'));

    expect(find.text('Follow Requests Route'), findsOneWidget);
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 3),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  for (var i = 0; i < maxTicks; i++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(step);
  }
}

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository({required List<NotificationEntity> notifications})
      : _notifications = notifications;

  final List<NotificationEntity> _notifications;

  @override
  Stream<List<NotificationEntity>> getNotifications() =>
      Stream.value(_notifications);

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<bool> getPushEnabled() async => true;

  @override
  Future<void> setPushEnabled(bool enabled) async {}
}
