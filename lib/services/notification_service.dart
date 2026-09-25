import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sifir_atik/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channel = AndroidNotificationChannel(
    'requests',
    'Talep bildirimleri',
    description: 'İlan talepleri ve talep durumu değişiklikleri',
    importance: Importance.high,
  );

  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _tapController = StreamController<void>.broadcast();

  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  String? _userId;
  String? _token;
  bool _localNotificationsReady = false;

  Stream<void> get notificationTaps => _tapController.stream;

  Future<void> initialize(String userId) async {
    if (Firebase.apps.isEmpty || userId.isEmpty) return;
    if (_userId == userId) return;

    _userId = userId;
    await _initializeLocalNotifications();

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    await _messageSubscription?.cancel();
    _messageSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );

    await _openedSubscription?.cancel();
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((_) {
      _tapController.add(null);
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      scheduleMicrotask(() => _tapController.add(null));
    }

    await _tokenSubscription?.cancel();
    _tokenSubscription = messaging.onTokenRefresh.listen(_saveToken);
    await _registerCurrentToken();
  }

  Future<void> unregister(String userId) async {
    if (Firebase.apps.isEmpty || userId.isEmpty) return;

    final token = _token;
    if (token != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('devices')
            .doc(_documentIdFor(token))
            .delete();
      } catch (error) {
        debugPrint('Bildirim cihaz kaydı silinemedi: $error');
      }
    }

    _token = null;
    _userId = null;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsReady) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (_) => _tapController.add(null),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
    _localNotificationsReady = true;
  }

  Future<void> _registerCurrentToken() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(token);
    } catch (error) {
      debugPrint('Bildirim tokenı alınamadı: $error');
    }
  }

  Future<void> _saveToken(String token) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;

    _token = token;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(_documentIdFor(token))
          .set({
            'token': token,
            'platform': defaultTargetPlatform.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (error) {
      debugPrint('Bildirim cihaz kaydı oluşturulamadı: $error');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: notification.title ?? 'Sıfır Atık',
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'requests',
          'Talep bildirimleri',
          channelDescription: 'İlan talepleri ve talep durumu değişiklikleri',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_notification',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  String _documentIdFor(String token) {
    return base64Url.encode(utf8.encode(token)).replaceAll('=', '');
  }
}
