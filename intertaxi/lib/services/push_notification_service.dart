import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_service.dart';

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _interTaxiChannel = AndroidNotificationChannel(
  'intertaxi',
  'InterTaxi',
  description: 'InterTaxi ride and message alerts',
  importance: Importance.max,
  playSound: true,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification == null) {
    await PushNotificationService.showMessage(message);
  }
}

abstract final class PushNotificationService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _notifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_interTaxiChannel);
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen(showMessage);
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await ApiService.registerPushToken(token);
      }
      messaging.onTokenRefresh.listen(ApiService.registerPushToken);
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user == null) return;
        final refreshedToken = await messaging.getToken();
        if (refreshedToken != null && refreshedToken.isNotEmpty) {
          await ApiService.registerPushToken(refreshedToken);
        }
      });
      _initialized = true;
    } catch (_) {}
  }

  static Future<void> showMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) return;
    await _notifications.show(
      message.hashCode,
      title ?? 'InterTaxi',
      body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'intertaxi',
          'InterTaxi',
          channelDescription: 'InterTaxi ride and message alerts',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      ),
    );
  }
}
