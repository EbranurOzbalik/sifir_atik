import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/models/user_notification.dart';
import 'package:sifir_atik/screens/notifications_page.dart';
import 'package:sifir_atik/services/notification_repository.dart';

void main() {
  group('NotificationRepository', () {
    test('bildirimleri tarihe göre getirir ve okunmuş işaretler', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = NotificationRepository(firestore: firestore);
      final notifications = firestore
          .collection('users')
          .doc('user-1')
          .collection('notifications');

      await notifications.doc('old').set({
        'title': 'Eski bildirim',
        'body': 'Eski içerik',
        'type': 'requestReceived',
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 20)),
      });
      await notifications.doc('new').set({
        'title': 'Yeni bildirim',
        'body': 'Yeni içerik',
        'type': 'requestAccepted',
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 24)),
      });

      final result = await repository.watchNotifications('user-1').first;
      expect(result.map((item) => item.title), [
        'Yeni bildirim',
        'Eski bildirim',
      ]);
      expect(result.first.type, UserNotificationType.requestAccepted);

      await repository.markAsRead('user-1', 'new');
      expect((await notifications.doc('new').get()).data()!['isRead'], isTrue);
    });

    test('tüm okunmamış bildirimleri tek işlemde günceller', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = NotificationRepository(firestore: firestore);
      final notifications = firestore
          .collection('users')
          .doc('user-1')
          .collection('notifications');

      await notifications.doc('one').set({
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
      await notifications.doc('two').set({
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      expect(await repository.watchUnreadCount('user-1').first, 2);
      await repository.markAllAsRead('user-1');
      expect(await repository.watchUnreadCount('user-1').first, 0);
    });
  });

  testWidgets('bildirim merkezi okunmamış bildirimi gösterir', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final repository = NotificationRepository(firestore: firestore);
    final reference = firestore
        .collection('users')
        .doc('user-1')
        .collection('notifications')
        .doc('notification-1');
    await reference.set({
      'title': 'Talebin kabul edildi',
      'body': 'İletişim bilgisi açıldı.',
      'type': 'requestAccepted',
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime(2026, 9, 24, 12, 30)),
    });

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(
          repository: repository,
          currentUserId: 'user-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Talebin kabul edildi'), findsOneWidget);
    expect(find.text('İletişim bilgisi açıldı.'), findsOneWidget);

    await tester.tap(find.text('Tümünü oku'));
    await tester.pumpAndSettle();
    expect((await reference.get()).data()!['isRead'], isTrue);
  });
}
