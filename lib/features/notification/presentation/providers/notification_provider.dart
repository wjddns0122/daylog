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
