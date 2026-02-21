import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:daylog/features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl();
});

final notificationsProvider = StreamProvider<List<NotificationEntity>>((ref) {
  final authState = ref.watch(authViewModelProvider);

  // If auth is still loading for the first time, we can show a loading state
  if (authState.isLoading && !authState.hasValue) {
    return const Stream
        .empty(); // This will emit AsyncData([]) or stay loading depending on ref needs
  }

  final user = authState.valueOrNull;
  if (user == null) {
    return const Stream.empty();
  }

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
