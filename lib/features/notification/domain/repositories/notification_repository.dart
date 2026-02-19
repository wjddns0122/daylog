import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Stream<List<NotificationEntity>> getNotifications();
  Future<void> markAllAsRead();
  Future<bool> getPushEnabled();
  Future<void> setPushEnabled(bool enabled);
}
