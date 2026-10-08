import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../modules/navigation/bottom_nav_controller.dart';
import '../../routes/app_routes.dart';

/// Opens the screen a tapped push notification names in its `screen` data
/// key, which the admin panel sets (oakspireweb `Firebase::SCREENS`): `home`,
/// `market`, `collection` or `subscription`.
///
/// A tap that launches the app arrives before the user is in the shell, so
/// the screen waits in [_pending] until [BottomNavController] calls
/// [openPending]. A signed-out user never reaches the shell, and the tap just
/// opens the app.
abstract final class NotificationTapRouter {
  NotificationTapRouter._();

  static const _tabs = {
    'home': BottomNavController.homeTab,
    'market': BottomNavController.marketTab,
    'collection': BottomNavController.collectionTab,
  };

  static const _subscription = 'subscription';

  static String? _pending;

  /// True while the shell is on the navigation stack.
  static bool _shellReady = false;

  static void handle(Map<String, dynamic> data) {
    final screen = data['screen']?.toString().trim() ?? '';
    if (kDebugMode) debugPrint('[FCM] Tap, screen: "$screen"');
    if (!_tabs.containsKey(screen) && screen != _subscription) return;
    _pending = screen;
    openPending();
  }

  static void shellOpened() {
    _shellReady = true;
    openPending();
  }

  static void shellClosed() => _shellReady = false;

  /// Opens the waiting screen, once the shell is there to open it from.
  static void openPending() {
    final screen = _pending;
    if (screen == null || !_shellReady) return;
    _pending = null;

    // Back to the shell first, closing whatever was pushed on top of it.
    Get.until((route) => route.settings.name == AppRoutes.shell);

    final tab = _tabs[screen];
    if (tab != null) {
      Get.find<BottomNavController>().setIndex(tab);
    } else if (screen == _subscription) {
      Get.toNamed(AppRoutes.subscription);
    }
  }
}
