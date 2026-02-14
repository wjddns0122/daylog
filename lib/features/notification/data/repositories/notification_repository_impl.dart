import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    this.useMockData = true,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final bool useMockData;

  @override
  Stream<List<NotificationEntity>> getNotifications() {
    if (useMockData) {
      return Stream.value(_mockNotifications);
    }

    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
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

    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
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
