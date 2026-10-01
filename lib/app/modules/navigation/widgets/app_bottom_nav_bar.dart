import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_haptics.dart';

/// One slot in [AppBottomNavBar]: an SVG asset or a Material icon.
class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.onTap,
    this.asset,
    this.icon,
    this.iconSize = 20,
  }) : assert(asset != null || icon != null);

  final String label;
  final String? asset;
  final IconData? icon;
  final double iconSize;
  final VoidCallback onTap;
}

/// The shell's bottom bar. A soft gold wash and a gold hairline slide
/// together to the selected slot; the selected icon lifts slightly.
///
/// [selectedIndex] is a slot index, not a tab index: the settings slot is
/// highlighted while its popup is open even though it is not a tab.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
  });

  final List<AppNavItem> items;
  final int selectedIndex;

  static const double _barHeight = 64;
  static const double _pillInset = 10;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppMotion.medium);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.navBarBackground,
        border: Border(top: BorderSide(color: AppColors.navBarBorder)),
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        maintainBottomViewPadding: true,
        child: SizedBox(
          height: _barHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slot = constraints.maxWidth / items.length;
              final hasSelection =
                  selectedIndex >= 0 && selectedIndex < items.length;
              final left = (hasSelection ? selectedIndex : 0) * slot;

              return Stack(
                children: [
                  // Wash behind the selected item.
                  AnimatedPositioned(
                    duration: duration,
                    curve: AppMotion.emphasizedDecelerate,
                    left: left + _pillInset,
                    width: slot - _pillInset * 2,
                    top: 8,
                    bottom: 8,
                    child: AnimatedOpacity(
                      duration: duration,
                      opacity: hasSelection ? 1 : 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.navIndicatorWash,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  // Gold hairline on the bar's top edge.
                  AnimatedPositioned(
                    duration: duration,
                    curve: AppMotion.emphasizedDecelerate,
                    left: left + slot / 2 - 14,
                    width: 28,
                    top: 0,
                    height: 2,
                    child: AnimatedOpacity(
                      duration: duration,
                      opacity: hasSelection ? 1 : 0,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(2),
                          ),
                          boxShadow: [
                            BoxShadow(color: AppColors.goldGlow, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _NavButton(
                            item: items[i],
                            selected: i == selectedIndex,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected});

  /// Same box for every icon, so labels line up whatever the icon size.
  static const double _iconBox = 24;

  final AppNavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textCream : AppColors.textMuted;
    final duration = AppMotion.of(context, AppMotion.fast);

    final icon = item.asset != null
        ? SvgPicture.asset(
            item.asset!,
            height: item.iconSize,
            width: item.iconSize,
            colorFilter: ColorFilter.mode(
              selected ? AppColors.gold2 : color,
              BlendMode.srcIn,
            ),
          )
        : Icon(
            item.icon,
            size: item.iconSize + 2,
            color: selected ? AppColors.gold2 : color,
          );

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: () {
          AppHaptics.selection();
          item.onTap();
        },
        radius: 30,
        highlightColor: Colors.transparent,
        splashColor: AppColors.navIndicatorWash,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSlide(
              offset: selected ? const Offset(0, -0.08) : Offset.zero,
              duration: duration,
              curve: AppMotion.emphasized,
              child: AnimatedScale(
                scale: selected ? 1.1 : 1,
                duration: duration,
                curve: AppMotion.emphasized,
                child: SizedBox.square(
                  dimension: _iconBox,
                  child: Center(child: icon),
                ),
              ),
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: duration,
              curve: AppMotion.standard,
              style: AppTextStyles.uiNavLabel().copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(item.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
