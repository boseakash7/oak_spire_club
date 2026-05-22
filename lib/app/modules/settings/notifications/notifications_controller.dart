import 'dart:async';

import 'package:get/get.dart';

import '../../../core/firebase/firebase_notification_topics.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/notification_prefs_model.dart';

class NotificationsController extends GetxController {
  final prefs = const NotificationPrefsModel().obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    prefs.value = NotificationPrefsModel.fromJson(AppStorage.notificationPrefs);
    unawaited(_syncTopicsFromStoredPrefs());
  }

  Future<void> _syncTopicsFromStoredPrefs() async {
    try {
      await FirebaseNotificationTopics.syncFromPrefs(prefs.value);
    } catch (_) {
      // Best-effort on open; toggles surface errors to the user.
    }
  }

  Future<void> _persistLocal(NotificationPrefsModel next) async {
    prefs.value = next;
    await AppStorage.setNotificationPrefs(next.toJson());
  }

  Future<void> _updatePreference(String preferenceKey, bool enabled) async {
    final previous = prefs.value;
    final optimistic = previous.copyWithPreferenceKey(preferenceKey, enabled);
    await _persistLocal(optimistic);

    isSaving.value = true;
    try {
      if (preferenceKey == NotificationPreferenceKey.pushNotifications) {
        await FirebaseNotificationTopics.setPushMasterEnabled(
          enabled,
          optimistic,
        );
      } else if (optimistic.pushEnabled) {
        await FirebaseNotificationTopics.setPreferenceEnabled(
          preferenceKey,
          enabled,
        );
      }
    } catch (e) {
      await _persistLocal(previous);
      try {
        await FirebaseNotificationTopics.syncFromPrefs(previous);
      } catch (_) {}
      await AppSnackbar.error(e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> setPushEnabled(bool value) => _updatePreference(
        NotificationPreferenceKey.pushNotifications,
        value,
      );

  Future<void> setCollectionAlerts(bool value) => _updatePreference(
        NotificationPreferenceKey.collectionValue,
        value,
      );

  Future<void> setMarketBenchmarkAlerts(bool value) => _updatePreference(
        NotificationPreferenceKey.marketBenchmarks,
        value,
      );

  Future<void> setPriceMovementAlerts(bool value) => _updatePreference(
        NotificationPreferenceKey.priceMovement,
        value,
      );

  Future<void> setProductUpdates(bool value) => _updatePreference(
        NotificationPreferenceKey.tipsUpdates,
        value,
      );
}
