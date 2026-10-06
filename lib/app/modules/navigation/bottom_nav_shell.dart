import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/exit_app_bottom_sheet.dart';
import '../collection/collection_view.dart';
import '../dashboard/dashboard_view.dart';
import '../market/market_view.dart';
import '../profile/settings_menu_popup.dart';
import 'bottom_nav_controller.dart';
import 'widgets/app_bottom_nav_bar.dart';
import 'widgets/lazy_tab_stack.dart';

class BottomNavShell extends GetView<BottomNavController> {
  const BottomNavShell({super.key});

  /// Nav slot of the settings item (it opens a popup, not a tab).
  static const int _settingsSlot = 3;

  /// Home first: it is where the app opens, a summary of the market and the
  /// user's collection that links into the other two. Collection keeps the
  /// full insights (value chart, top moved, quick stats).
  static const _pages = <Widget>[
    DashboardView(),
    MarketView(),
    CollectionView(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_onShellBackPressed(context));
      },
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: const AppHeader(),
        body: Obx(
          () => LazyTabStack(index: controller.index.value, children: _pages),
        ),
        bottomNavigationBar: Obx(
          () => AppBottomNavBar(
            selectedIndex: controller.settingsMenuOpen.value
                ? _settingsSlot
                : controller.index.value,
            items: [
              AppNavItem(
                label: 'Home',
                asset: AppAssets.navHome,
                iconSize: 20,
                onTap: () =>
                    _selectTab(BottomNavController.homeTab, 'bottom_nav_home'),
              ),
              AppNavItem(
                label: 'Market',
                asset: AppAssets.navMarket,
                iconSize: 22,
                onTap: () => _selectTab(
                  BottomNavController.marketTab,
                  'bottom_nav_market',
                ),
              ),
              AppNavItem(
                label: 'Collection',
                asset: AppAssets.navCollectionActive,
                iconSize: 19,
                onTap: () => _selectTab(
                  BottomNavController.collectionTab,
                  'bottom_nav_collection',
                ),
              ),
              AppNavItem(
                label: 'Settings',
                icon: Icons.settings_rounded,
                onTap: () {
                  _logTap('bottom_nav_settings');
                  unawaited(showSettingsPopup(context));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTab(int index, String analyticsKey) {
    _logTap(analyticsKey);
    controller.setIndex(index);
  }

  void _logTap(String key) {
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(AppAnalyticsController.to.logTap(key));
    }
  }

  Future<void> _onShellBackPressed(BuildContext context) async {
    if (controller.settingsMenuOpen.value) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (controller.index.value != BottomNavController.homeTab) {
      controller.setIndex(BottomNavController.homeTab);
      return;
    }

    _logTap('exit_app_prompt');

    final shouldExit = await showExitAppBottomSheet(context);
    if (!context.mounted) return;

    if (shouldExit) {
      _logTap('exit_app_confirm');
      await SystemNavigator.pop();
    }
  }
}
