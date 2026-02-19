import 'package:daylog/features/notification/domain/entities/notification_entity.dart';
import 'package:daylog/features/notification/domain/repositories/notification_repository.dart';
import 'package:daylog/features/notification/presentation/providers/notification_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pushEnabledProvider persists toggled value', () async {
    SharedPreferences.setMockInitialValues({
      'notification.push_enabled': false,
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(pushEnabledProvider.future), isFalse);

    await container.read(pushEnabledProvider.notifier).setPushEnabled(true);
    expect(container.read(pushEnabledProvider).valueOrNull, isTrue);

    final secondContainer = ProviderContainer();
    addTearDown(secondContainer.dispose);
    expect(await secondContainer.read(pushEnabledProvider.future), isTrue);
  });

  test('pushEnabledProvider surfaces repository error state', () async {
    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(_FailingRepository()),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(pushEnabledProvider.future),
      throwsA(isA<StateError>()),
    );

    final state = container.read(pushEnabledProvider);
    expect(state.hasError, isTrue);
  });

  test('setPushEnabled exposes save failure as AsyncError', () async {
    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider
            .overrideWithValue(_SetFailingRepository()),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(pushEnabledProvider.future), isTrue);

    await container.read(pushEnabledProvider.notifier).setPushEnabled(false);

    final state = container.read(pushEnabledProvider);
    expect(state.hasError, isTrue);
  });
}

class _FailingRepository implements NotificationRepository {
  @override
  Future<bool> getPushEnabled() async => throw StateError('load failed');

  @override
  Future<void> markAllAsRead() async {}

  @override
  Stream<List<NotificationEntity>> getNotifications() =>
      const Stream<List<NotificationEntity>>.empty();

  @override
  Future<void> setPushEnabled(bool enabled) async =>
      throw StateError('save failed');
}

class _SetFailingRepository implements NotificationRepository {
  @override
  Future<bool> getPushEnabled() async => true;

  @override
  Future<void> markAllAsRead() async {}

  @override
  Stream<List<NotificationEntity>> getNotifications() =>
      const Stream<List<NotificationEntity>>.empty();

  @override
  Future<void> setPushEnabled(bool enabled) async =>
      throw StateError('save failed');
}
