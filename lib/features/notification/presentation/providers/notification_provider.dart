import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl();
});

final notificationsProvider = StreamProvider<List<NotificationEntity>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotifications();
});

class PushEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final repository = ref.watch(notificationRepositoryProvider);
    return repository.getPushEnabled();
  }

  Future<void> setPushEnabled(bool enabled) async {
    final repository = ref.read(notificationRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.setPushEnabled(enabled);
      return enabled;
    });
  }
}

final pushEnabledProvider =
    AsyncNotifierProvider<PushEnabledNotifier, bool>(PushEnabledNotifier.new);
