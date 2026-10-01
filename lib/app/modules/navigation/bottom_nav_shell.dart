import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/exit_app_bottom_sheet.dart';
import '../collection/collection_view.dart';
import '../home/home_view.dart';
import '../market/market_view.dart';
import '../profile/settings_menu_popup.dart';
import 'bottom_nav_controller.dart';
import 'widgets/app_bottom_nav_bar.dart';
import 'widgets/lazy_tab_stack.dart';

class BottomNavShell extends GetView<BottomNavController> {
  const BottomNavShell({super.key});

  /// Nav slot of the settings item (it opens a popup, not a tab).
  static const int _settingsSlot = 3;

  static const _pages = <Widget>[HomeView(), CollectionView(), MarketView()];

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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kShellAppBarHeight),
          child: GetX<BottomNavController>(
            builder: (c) => AppHeader(title: c.headerTitle),
          ),
        ),
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
                asset: AppAssets.navHomeFilled,
                iconSize: 19,
                onTap: () => _selectTab(0, 'bottom_nav_home'),
              ),
              AppNavItem(
                label: 'Collection',
                asset: AppAssets.navCollectionActive,
                iconSize: 19,
                onTap: () => _selectTab(1, 'bottom_nav_collection'),
              ),
              AppNavItem(
                label: 'Benchmark',
                asset: AppAssets.navMarket,
                iconSize: 22,
                onTap: () => _selectTab(2, 'bottom_nav_market'),
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

    if (controller.index.value != 0) {
      controller.setIndex(0);
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
