import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';
import '../../core/widgets/app_header.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../collection/collection_view.dart';
import '../home/home_view.dart';
import '../market/market_view.dart';
import '../profile/profile_view.dart';
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
      const ProfileView(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppHeader(),
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
                      onTap: () => controller.setIndex(0),
                    ),
                    _NavItem(
                      label: 'Collection',
                      asset: AppAssets.navCollectionActive,
                      selected: selected == 1,
                      onTap: () => controller.setIndex(1),
                    ),
                    _NavItem(
                      label: 'Taste',
                      asset: AppAssets.navCollectionInactive,
                      selected: selected == 2,
                      onTap: () => controller.setIndex(2),
                    ),
                    _NavItem(
                      label: 'Market',
                      asset: AppAssets.navCollectionInactive,
                      selected: selected == 3,
                      onTap: () => controller.setIndex(3),
                    ),
                    _NavItem(
                      label: 'Profile',
                      asset: '',
                      selected: selected == 4,
                      onTap: () => controller.setIndex(4),
                      iconOverride: _ProfileNavIcon(
                        selected: selected == 4,
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
  });

  final String label;
  final String asset;
  final bool selected;
  final VoidCallback onTap;
  final Widget? iconOverride;

  static const double _iconSize = 19;

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
                height: _iconSize,
                width: _iconSize,
                child: IconTheme(
                  data: IconThemeData(color: color, size: _iconSize),
                  child: iconOverride!,
                ),
              )
            else
              SvgPicture.asset(
                asset,
                height: _iconSize,
                width: _iconSize,
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

class _ProfileNavIcon extends StatelessWidget {
  const _ProfileNavIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textCream : AppColors.textMuted;
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 9,
            height: 9,
            child: SvgPicture.asset(
              AppAssets.navProfileHead,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 18,
            height: 10,
            child: SvgPicture.asset(
              AppAssets.navProfileBody,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        ),
      ],
    );
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

