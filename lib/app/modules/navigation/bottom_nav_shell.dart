import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_header.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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
      const _PlaceholderTab(label: 'Taste'),
      const MarketView(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kShellAppBarHeight),
        child: Obx(
          () => AppHeader(
            title: controller.index.value == 3
                ? 'Benchmark'
                : AppConstants.appName,
          ),
        ),
      ),
      body: Obx(() => pages[controller.index.value]),
      bottomNavigationBar: Obx(
        () {
          final selected = controller.index.value;
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.navBarBackground,
              border: Border(
                top: BorderSide(color: AppColors.navBarBorder),
              ),
            ),
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              minimum: EdgeInsets.zero,
              maintainBottomViewPadding: true,
              child: SizedBox(
                height: 54,
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
                            AppAnalyticsController.to
                                .logTap('bottom_nav_collection'),
                          );
                        }
                        controller.setIndex(1);
                      },
                    ),
                    _NavItem(
                      label: 'Taste',
                      asset: AppAssets.navTaste,
                      selected: selected == 2,
                      onTap: () {
                        if (Get.isRegistered<AppAnalyticsController>()) {
                          unawaited(
                            AppAnalyticsController.to.logTap('bottom_nav_taste'),
                          );
                        }
                        controller.setIndex(2);
                      },
                    ),
                    _NavItem(
                      label: 'Market',
                      asset: AppAssets.navMarket,
                      selected: selected == 3,
                      iconSize: 22,
                      onTap: () {
                        if (Get.isRegistered<AppAnalyticsController>()) {
                          unawaited(
                            AppAnalyticsController.to.logTap('bottom_nav_market'),
                          );
                        }
                        controller.setIndex(3);
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
        },
      ),
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

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? AppColors.textCream : AppColors.textMuted;

    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            if (iconOverride != null)
              SizedBox(
                height: iconSize,
                width: iconSize,
                child: IconTheme(
                  data: IconThemeData(color: color, size: iconSize),
                  child: iconOverride!,
                ),
              )
            else
              SvgPicture.asset(
                asset,
                height: iconSize,
                width: iconSize,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.body16().copyWith(
                fontSize: 10,
                height: 1.0,
                color: color,
                fontWeight: FontWeight.w400,
                fontFamily: 'Inter',
              ),
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

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black,
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.heading32Bold().copyWith(fontSize: 18),
      ),
    );
  }
}

