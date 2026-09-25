import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sifir_atik/models/user_notification.dart';

class NotificationRepository {
  const NotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  bool get _isReady => _firestore != null || Firebase.apps.isNotEmpty;

  FirebaseFirestore get _database => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notifications(String userId) {
    return _database
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  Stream<List<UserNotification>> watchNotifications(String userId) async* {
    if (!_isReady || userId.isEmpty) {
      yield const [];
      return;
    }

    try {
      final query = _notifications(
        userId,
      ).orderBy('createdAt', descending: true).limit(100);

      await for (final snapshot in query.snapshots()) {
        yield snapshot.docs.map(UserNotification.fromFirestore).toList();
      }
    } catch (_) {
      yield const [];
    }
  }

  Stream<int> watchUnreadCount(String userId) async* {
    if (!_isReady || userId.isEmpty) {
      yield 0;
      return;
    }

    try {
      final query = _notifications(userId).where('isRead', isEqualTo: false);
      await for (final snapshot in query.snapshots()) {
        yield snapshot.docs.length;
      }
    } catch (_) {
      yield 0;
    }
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    if (!_isReady || userId.isEmpty || notificationId.isEmpty) return;

    await _notifications(userId).doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    if (!_isReady || userId.isEmpty) return;

    final snapshot = await _notifications(
      userId,
    ).where('isRead', isEqualTo: false).limit(500).get();
    if (snapshot.docs.isEmpty) return;

    final batch = _database.batch();
    for (final document in snapshot.docs) {
      batch.update(document.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
