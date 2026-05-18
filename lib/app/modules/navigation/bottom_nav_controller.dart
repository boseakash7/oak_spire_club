import 'dart:async';

import 'package:get/get.dart';

import '../../core/analytics/analytics_screens.dart';
import '../../core/analytics/app_analytics_controller.dart';
import '../home/home_controller.dart';

class BottomNavController extends GetxController {
  final index = 0.obs;

  /// True while settings popup is visible (settings is not a tab page).
  final settingsMenuOpen = false.obs;

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
    // Home is not built while other tabs are shown; refresh when returning so
    // collection value / counts match without restarting the app.
    if (value == 0 &&
        previous != 0 &&
        Get.isRegistered<HomeController>()) {
      unawaited(
        Get.find<HomeController>().fetchHomeData(forceRefresh: false),
      );
    }
  }
}

