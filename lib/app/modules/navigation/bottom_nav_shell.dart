import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../core/animations/app_motion.dart';
import '../../core/constants/app_assets.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/exit_app_bottom_sheet.dart';
import '../collection/collection_view.dart';
import '../home/home_view.dart';
import '../market/market_view.dart';
import '../profile/settings_popup.dart';
import 'bottom_nav_controller.dart';

class BottomNavShell extends GetView<BottomNavController> {
  const BottomNavShell({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeView(),
      const CollectionView(),
      // const _PlaceholderTab(label: 'Taste'),
      const MarketView(),
    ];

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
          () =>
              _LazyIndexedStack(index: controller.index.value, children: pages),
        ),
        bottomNavigationBar: Obx(() {
          final selected = controller.index.value;
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.navBarBackground,
              border: Border(top: BorderSide(color: AppColors.navBarBorder)),
            ),
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              minimum: EdgeInsets.zero,
              maintainBottomViewPadding: true,
              child: SizedBox(
                height: 62,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      label: 'Home',
                      asset: AppAssets.navHomeFilled,
                      selected: selected == 0,
                      onTap: () {
                        if (Get.isRegistered<AppAnalyticsController>()) {
                          unawaited(
                            AppAnalyticsController.to.logTap('bottom_nav_home'),
                          );
                        }
                        AppHaptics.selection();
                        controller.setIndex(0);
                      },
                    ),
                    _NavItem(
                      label: 'Collection',
                      asset: AppAssets.navCollectionActive,
                      selected: selected == 1,
                      onTap: () {
                        if (Get.isRegistered<AppAnalyticsController>()) {
                          unawaited(
                            AppAnalyticsController.to.logTap(
                              'bottom_nav_collection',
                            ),
                          );
                        }
                        AppHaptics.selection();
                        controller.setIndex(1);
                      },
                    ),
                    // _NavItem(
                    //   label: 'Taste',
                    //   asset: AppAssets.navTaste,
                    //   selected: selected == 2,
                    //   onTap: () {
                    //     if (Get.isRegistered<AppAnalyticsController>()) {
                    //       unawaited(
                    //         AppAnalyticsController.to.logTap('bottom_nav_taste'),
                    //       );
                    //     }
                    //     controller.setIndex(2);
                    //   },
                    // ),
                    _NavItem(
                      label: 'Benchmark',
                      asset: AppAssets.navMarket,
                      selected: selected == 2,
                      iconSize: 22,
                      onTap: () {
                        if (Get.isRegistered<AppAnalyticsController>()) {
                          unawaited(
                            AppAnalyticsController.to.logTap(
                              'bottom_nav_market',
                            ),
                          );
                        }
                        AppHaptics.selection();
                        controller.setIndex(2);
                      },
                    ),
                    Obx(
                      () => _NavItem(
                        label: 'Settings',
                        asset: '',
                        selected: controller.settingsMenuOpen.value,
                        onTap: () {
                          if (Get.isRegistered<AppAnalyticsController>()) {
                            unawaited(
                              AppAnalyticsController.to.logTap(
                                'bottom_nav_settings',
                              ),
                            );
                          }
                          AppHaptics.selection();
                          unawaited(showSettingsPopup(context));
                        },
                        iconOverride: _SettingsNavIcon(
                          selected: controller.settingsMenuOpen.value,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
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

    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(AppAnalyticsController.to.logTap('exit_app_prompt'));
    }

    final shouldExit = await showExitAppBottomSheet(context);
    if (!context.mounted) return;

    if (shouldExit) {
      if (Get.isRegistered<AppAnalyticsController>()) {
        unawaited(AppAnalyticsController.to.logTap('exit_app_confirm'));
      }
      await SystemNavigator.pop();
    }
  }
}

/// [IndexedStack] that builds each tab on first visit and keeps it alive after.
///
/// A plain IndexedStack builds every child immediately, which would fire all
/// three tabs' initial fetches on cold start. Rebuilding on each switch (the
/// previous behaviour) is the other extreme: it throws away scroll position,
/// replays entrance animations and redraws the chart from zero every time.
/// This keeps the cheap cold start and the cheap switches.
class _LazyIndexedStack extends StatefulWidget {
  const _LazyIndexedStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<_LazyIndexedStack> {
  late final List<bool> _visited = List<bool>.generate(
    widget.children.length,
    (i) => i == widget.index,
  );

  @override
  void didUpdateWidget(_LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _markVisited();
  }

  void _markVisited() {
    final i = widget.index;
    if (i >= 0 && i < _visited.length) _visited[i] = true;
  }

  @override
  Widget build(BuildContext context) {
    _markVisited();
    return IndexedStack(
      index: widget.index,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          if (_visited[i]) widget.children[i] else const SizedBox.shrink(),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
    this.iconOverride,
    this.iconSize = _defaultIconSize,
  });

  final String label;
  final String asset;
  final bool selected;
  final VoidCallback onTap;
  final Widget? iconOverride;
  final double iconSize;

  static const double _defaultIconSize = 19;

  /// Width of the gold indicator that slides in above the active tab.
  static const double _indicatorWidth = 22;
  static const double _indicatorHeight = 2;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textCream : AppColors.textMuted;

    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Indicator keeps its slot whether or not the tab is active, so
            // icons never shift vertically between states.
            AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              width: selected ? _indicatorWidth : 0,
              height: _indicatorHeight,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(_indicatorHeight),
              ),
            ),
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              child: iconOverride != null
                  ? SizedBox(
                      height: iconSize,
                      width: iconSize,
                      child: IconTheme(
                        data: IconThemeData(color: color, size: iconSize),
                        child: iconOverride!,
                      ),
                    )
                  : SvgPicture.asset(
                      asset,
                      height: iconSize,
                      width: iconSize,
                      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                    ),
            ),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              style: AppTextStyles.uiNavLabel().copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsNavIcon extends StatelessWidget {
  const _SettingsNavIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textCream : AppColors.textMuted;
    return Icon(Icons.settings_rounded, color: color, size: 22);
  }
}

// class _PlaceholderTab extends StatelessWidget {
//   const _PlaceholderTab({required this.label});
//   final String label;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: AppColors.black,
//       alignment: Alignment.center,
//       child: Text(
//         label,
//         style: AppTextStyles.heading32Bold().copyWith(fontSize: 18),
//       ),
//     );
//   }
// }
