import 'dart:async';

import 'package:get/get.dart';

import '../../core/analytics/analytics_screens.dart';
import '../../core/analytics/app_analytics_controller.dart';
import '../home/home_controller.dart';

class BottomNavController extends GetxController {
  final index = 0.obs;

  /// True while settings popup is visible (settings is not a tab page).
  final settingsMenuOpen = false.obs;

  /// Tab indices. Home is the landing tab; Settings (slot 3) is a popup.
  static const int homeTab = 0;
  static const int marketTab = 1;
  static const int collectionTab = 2;

  void setIndex(int value) {
    final previous = index.value;
    if (value != previous && Get.isRegistered<AppAnalyticsController>()) {
      unawaited(
        AppAnalyticsController.to.logScreenView(
          AnalyticsScreens.shellTabScreenName(value),
        ),
      );
    }
    index.value = value;

    // Home's collection card and Collection's insights (chart and
    // quick stats) both read HomeController: refresh it quietly on the way in.
    if ((value == homeTab || value == collectionTab) &&
        value != previous &&
        Get.isRegistered<HomeController>()) {
      unawaited(
        Get.find<HomeController>().fetchHomeData(
          forceRefresh: false,
          background: true,
        ),
      );
    }
  }
}
