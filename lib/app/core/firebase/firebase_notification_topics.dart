import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/notification_prefs_model.dart';

/// FCM topic names for notification preference toggles (no REST API on toggle).
abstract final class FirebaseNotificationTopics {
  FirebaseNotificationTopics._();

  static const _prefix = 'oakspire_';

  static const collection = '${_prefix}collection';
  static const market = '${_prefix}market';
  static const priceMovement = '${_prefix}price_movement';
  static const tips = '${_prefix}tips';

  static const alertPreferenceKeys = [
    NotificationPreferenceKey.collectionValue,
    NotificationPreferenceKey.marketBenchmarks,
    NotificationPreferenceKey.priceMovement,
    NotificationPreferenceKey.tipsUpdates,
  ];

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static String? topicForPreferenceKey(String key) => switch (key) {
        NotificationPreferenceKey.collectionValue => collection,
        NotificationPreferenceKey.marketBenchmarks => market,
        NotificationPreferenceKey.priceMovement => priceMovement,
        NotificationPreferenceKey.tipsUpdates => tips,
        _ => null,
      };

  /// Aligns device topic subscriptions with stored preferences.
  static Future<void> syncFromPrefs(NotificationPrefsModel prefs) async {
    if (kIsWeb) return;

    if (!prefs.pushEnabled) {
      await _unsubscribeAllAlertTopics();
      return;
    }

    for (final key in alertPreferenceKeys) {
      final topic = topicForPreferenceKey(key);
      if (topic == null) continue;
      final enabled = _isPreferenceEnabled(prefs, key);
      if (enabled) {
        await _messaging.subscribeToTopic(topic);
      } else {
        await _messaging.unsubscribeFromTopic(topic);
      }
    }
  }

  static Future<void> setPushMasterEnabled(
    bool enabled,
    NotificationPrefsModel prefs,
  ) async {
    if (kIsWeb) return;

    if (!enabled) {
      await _unsubscribeAllAlertTopics();
      return;
    }

    final granted = await requestPermissionIfNeeded();
    if (!granted) {
      throw StateError(
        'Notification permission was not granted. Enable alerts in system settings.',
      );
    }

    await syncFromPrefs(prefs);
  }

  static Future<void> setPreferenceEnabled(String key, bool enabled) async {
    if (kIsWeb) return;

    final topic = topicForPreferenceKey(key);
    if (topic == null) return;

    if (enabled) {
      await _messaging.subscribeToTopic(topic);
    } else {
      await _messaging.unsubscribeFromTopic(topic);
    }
  }

  static Future<bool> requestPermissionIfNeeded() async {
    if (kIsWeb) return false;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final status = settings.authorizationStatus;
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  static Future<void> _unsubscribeAllAlertTopics() async {
    for (final key in alertPreferenceKeys) {
      final topic = topicForPreferenceKey(key);
      if (topic == null) continue;
      await _messaging.unsubscribeFromTopic(topic);
    }
  }

  static bool _isPreferenceEnabled(NotificationPrefsModel prefs, String key) =>
      switch (key) {
        NotificationPreferenceKey.collectionValue => prefs.collectionAlerts,
        NotificationPreferenceKey.marketBenchmarks =>
          prefs.marketBenchmarkAlerts,
        NotificationPreferenceKey.priceMovement => prefs.priceMovementAlerts,
        NotificationPreferenceKey.tipsUpdates => prefs.productUpdates,
        _ => false,
      };
}
