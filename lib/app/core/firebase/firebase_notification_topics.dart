import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/notification_prefs_model.dart';
import '../../data/models/user_model.dart';
import '../storage/app_storage.dart';

/// FCM topic names for notification preference toggles and user status routing.
abstract final class FirebaseNotificationTopics {
  FirebaseNotificationTopics._();

  static const _prefix = 'oakspire_';

  // Preference topics
  static const collection = '${_prefix}collection';
  static const market = '${_prefix}market';
  static const priceMovement = '${_prefix}price_movement';
  static const tips = '${_prefix}tips';

  // Registration topics
  static const unregisteredUsers = '${_prefix}unregistered_users';
  static const registeredUsers = '${_prefix}registered_users';
  static const topicLogout = '${_prefix}topic_logout';

  static const allRegistrationTopics = [
    unregisteredUsers,
    registeredUsers,
    topicLogout,
  ];

  // Subscription tier topics
  static const freeUser = '${_prefix}free_user';
  static const paidUser = '${_prefix}paid_user';
  static const trialUser = '${_prefix}trial_user';

  static const allTierTopics = [
    freeUser,
    paidUser,
    trialUser,
  ];

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

  /// First app launch only: subscribe default alert topics in the background.
  /// Later launches and user toggles are handled elsewhere.
  static Future<void> subscribeOnFirstLaunchIfNeeded() async {
    if (kIsWeb) return;
    if (AppStorage.notificationTopicsInitialSyncDone) return;

    final stored = AppStorage.notificationPrefs;
    final prefs = NotificationPrefsModel.fromJson(stored);
    if (stored == null) {
      await AppStorage.setNotificationPrefs(prefs.toJson());
    }

    try {
      if (prefs.pushEnabled) {
        for (final key in alertPreferenceKeys) {
          if (!_isPreferenceEnabled(prefs, key)) continue;
          final topic = topicForPreferenceKey(key);
          if (topic == null) continue;
          await _messaging.subscribeToTopic(topic);
          if (kDebugMode) {
            debugPrint('[FCM] First launch subscribed: $topic');
          }
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FCM] First-launch topic subscribe failed: $e\n$st');
      }
    } finally {
      await AppStorage.setNotificationTopicsInitialSyncDone(true);
    }
  }

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

  /// Synchronizes unregistered status topic (`oakspire_unregistered_users`).
  /// Unsubscribes from registered/logout/tier topics.
  static Future<void> syncUnregisteredTopic() async {
    if (kIsWeb) return;

    final currentTopic = AppStorage.currentRegistrationTopic;
    if (currentTopic == unregisteredUsers) return;

    try {
      await _messaging.unsubscribeFromTopic(registeredUsers);
      await _messaging.unsubscribeFromTopic(topicLogout);
      for (final topic in allTierTopics) {
        await _messaging.unsubscribeFromTopic(topic);
      }
      await AppStorage.setCurrentTierTopic(null);
      await _messaging.subscribeToTopic(unregisteredUsers);
      await AppStorage.setCurrentRegistrationTopic(unregisteredUsers);
      if (kDebugMode) {
        debugPrint('[FCM] Subscribed to unregistered topic: $unregisteredUsers');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FCM] Unregistered topic sync failed: $e\n$st');
      }
    }
  }

  /// Called ONLY when a brand-new user registers on the sign-up page.
  /// Subscribes to `oakspire_registered_users` and unsubscribes from unregistered/logout topics.
  static Future<void> syncNewRegistrationTopic() async {
    if (kIsWeb) return;

    try {
      await _messaging.unsubscribeFromTopic(unregisteredUsers);
      await _messaging.unsubscribeFromTopic(topicLogout);
      await _messaging.subscribeToTopic(registeredUsers);
      await AppStorage.setCurrentRegistrationTopic(registeredUsers);
      if (kDebugMode) {
        debugPrint(
          '[FCM] New registration complete: Subscribed ONLY on signup to: $registeredUsers',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FCM] New registration topic sync failed: $e\n$st');
      }
    }
  }

  /// Handles user logout: Unsubscribes from ALL existing topics (alerts, registration, tiers)
  /// in parallel and subscribes ONLY to `oakspire_topic_logout`.
  static Future<void> syncLogoutTopic() async {
    if (kIsWeb) return;

    try {
      final unsubs = <Future<void>>[];

      // 1. Unsubscribe from all alert preference topics
      for (final key in alertPreferenceKeys) {
        final topic = topicForPreferenceKey(key);
        if (topic != null) {
          unsubs.add(_messaging.unsubscribeFromTopic(topic));
        }
      }

      // 2. Unsubscribe from all registration topics (except topicLogout)
      for (final topic in allRegistrationTopics) {
        if (topic != topicLogout) {
          unsubs.add(_messaging.unsubscribeFromTopic(topic));
        }
      }

      // 3. Unsubscribe from all tier topics
      for (final topic in allTierTopics) {
        unsubs.add(_messaging.unsubscribeFromTopic(topic));
      }

      // Run all unsubscriptions in parallel with a 2.5s safety timeout
      await Future.wait(unsubs).timeout(
        const Duration(milliseconds: 2500),
        onTimeout: () => [],
      );

      // 4. Clear stored topic states
      await AppStorage.setCurrentRegistrationTopic(null);
      await AppStorage.setCurrentTierTopic(null);

      // 5. Subscribe ONLY to topicLogout
      await _messaging.subscribeToTopic(topicLogout);

      if (kDebugMode) {
        debugPrint(
          '[FCM] Logout complete: Unsubscribed ALL topics and subscribed ONLY to: $topicLogout',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FCM] Logout topic sync failed: $e\n$st');
      }
    }
  }

  /// Synchronizes user subscription tier topic (`oakspire_free_user`, `oakspire_paid_user`, or `oakspire_trial_user`).
  /// Always unsubscribes old tier topics while subscribing to the new active tier topic.
  /// Preserves existing alert notification preferences.
  static Future<void> syncUserTierTopic(UserModel? user) async {
    if (kIsWeb) return;
    if (user == null) {
      await syncUnregisteredTopic();
      return;
    }

    // Unsubscribe from unregistered & logout topics if coming from guest/logged-out state
    try {
      await _messaging.unsubscribeFromTopic(unregisteredUsers);
      await _messaging.unsubscribeFromTopic(topicLogout);
    } catch (_) {}

    final String targetTierTopic;
    if (user.isFreeUser) {
      targetTierTopic = freeUser;
    } else if (user.hasActiveSubscription) {
      targetTierTopic = paidUser;
    } else {
      targetTierTopic = trialUser;
    }

    final currentTier = AppStorage.currentTierTopic;
    if (currentTier == targetTierTopic) {
      if (kDebugMode) {
        debugPrint('[FCM] Tier topic already synced: $targetTierTopic');
      }
      return;
    }

    try {
      for (final topic in allTierTopics) {
        if (topic == targetTierTopic) continue;
        await _messaging.unsubscribeFromTopic(topic);
        if (kDebugMode) {
          debugPrint('[FCM] Unsubscribed old tier topic: $topic');
        }
      }

      await _messaging.subscribeToTopic(targetTierTopic);
      await AppStorage.setCurrentTierTopic(targetTierTopic);
      if (kDebugMode) {
        debugPrint('[FCM] Subscribed to tier topic: $targetTierTopic');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FCM] Tier topic sync failed: $e\n$st');
      }
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
