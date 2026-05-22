import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../firebase_options.dart';

/// Background FCM handler (app terminated / in background).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Shows push notifications while the app is open (foreground).
abstract final class FirebasePushNotifications {
  FirebasePushNotifications._();

  static const String _androidChannelId = 'oakspire_alerts';

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    _androidChannelId,
    'Oak Spire Alerts',
    description: 'Collection, market, and account notifications',
    importance: Importance.high,
  );

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();

    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);
  }

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_androidChannel);
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    // iOS can show the banner via setForegroundNotificationPresentationOptions.
    if (Platform.isIOS && message.notification != null) return;

    await _showLocalNotification(message);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = _resolveTitle(message);
    final body = _resolveBody(message);
    if (title == null && body == null) return;

    final id = message.messageId?.hashCode ??
        message.sentTime?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;

    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      'Oak Spire Alerts',
      channelDescription: 'Collection, market, and account notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _local.show(
      id: id,
      title: title ?? 'Oak Spire Club',
      body: body ?? '',
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  static String? _resolveTitle(RemoteMessage message) {
    final fromNotification = message.notification?.title?.trim();
    if (fromNotification != null && fromNotification.isNotEmpty) {
      return fromNotification;
    }
    final fromData = message.data['title']?.toString().trim();
    if (fromData != null && fromData.isNotEmpty) return fromData;
    return null;
  }

  static String? _resolveBody(RemoteMessage message) {
    final fromNotification = message.notification?.body?.trim();
    if (fromNotification != null && fromNotification.isNotEmpty) {
      return fromNotification;
    }
    final fromData = message.data['body']?.toString().trim();
    if (fromData != null && fromData.isNotEmpty) return fromData;
    return null;
  }

  static void _onNotificationOpened(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('[FCM] Opened from notification: ${message.data}');
    }
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('[FCM] Local notification tap: ${response.payload}');
    }
  }
}
