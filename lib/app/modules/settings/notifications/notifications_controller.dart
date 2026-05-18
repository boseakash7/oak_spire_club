import 'package:get/get.dart';

import '../../../core/storage/app_storage.dart';
import '../../../data/models/notification_prefs_model.dart';

class NotificationsController extends GetxController {
  final prefs = const NotificationPrefsModel().obs;

  @override
  void onInit() {
    super.onInit();
    prefs.value = NotificationPrefsModel.fromJson(AppStorage.notificationPrefs);
  }

  Future<void> _persist(NotificationPrefsModel next) async {
    prefs.value = next;
    await AppStorage.setNotificationPrefs(next.toJson());
  }

  Future<void> setPushEnabled(bool value) async {
    await _persist(prefs.value.copyWith(pushEnabled: value));
  }

  Future<void> setCollectionAlerts(bool value) async {
    await _persist(prefs.value.copyWith(collectionAlerts: value));
  }

  Future<void> setMarketBenchmarkAlerts(bool value) async {
    await _persist(prefs.value.copyWith(marketBenchmarkAlerts: value));
  }

  Future<void> setPriceMovementAlerts(bool value) async {
    await _persist(prefs.value.copyWith(priceMovementAlerts: value));
  }

  Future<void> setProductUpdates(bool value) async {
    await _persist(prefs.value.copyWith(productUpdates: value));
  }
}
