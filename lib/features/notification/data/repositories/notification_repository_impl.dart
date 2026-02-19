import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    this.useMockData = false,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  final bool useMockData;
  static const String _pushEnabledKey = 'notification.push_enabled';

  FirebaseFirestore get _resolvedFirestore =>
      _firestore ?? FirebaseFirestore.instance;

  FirebaseAuth get _resolvedAuth => _auth ?? FirebaseAuth.instance;

  @override
  Stream<List<NotificationEntity>> getNotifications() {
    if (useMockData) {
      return Stream.value(_mockNotifications);
    }

    final user = _resolvedAuth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _resolvedFirestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationEntity.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> markAllAsRead() async {
    if (useMockData) {
      return;
    }

    final user = _resolvedAuth.currentUser;
    if (user == null) {
      return;
    }

    final snapshot = await _resolvedFirestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _resolvedFirestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Future<bool> getPushEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pushEnabledKey) ?? true;
  }

  @override
  Future<void> setPushEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushEnabledKey, enabled);
  }
}

final List<NotificationEntity> _mockNotifications = [
  NotificationEntity(
    id: 'n-film-1',
    title: 'Film Developed',
    message: 'Your photo is developed and ready to view.',
    type: NotificationType.filmDeveloped,
    createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
    isRead: false,
  ),
  NotificationEntity(
    id: 'n-like-1',
    title: 'New Like',
    message: '@jenny liked your latest memory.',
    type: NotificationType.like,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    isRead: true,
  ),
  NotificationEntity(
    id: 'n-comment-1',
    title: 'New Comment',
    message: '@mike commented: "The lighting is amazing."',
    type: NotificationType.comment,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    isRead: true,
  ),
];
