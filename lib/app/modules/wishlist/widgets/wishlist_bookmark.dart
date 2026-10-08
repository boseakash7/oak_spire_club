import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_pressable.dart';
import '../wishlist_controller.dart';

/// A round bookmark that adds the bottle to the wishlist in one tap, or takes
/// it off. Sits on the corner of a market row's art.
class WishlistBookmark extends StatelessWidget {
  const WishlistBookmark({
    super.key,
    required this.bottleId,
    this.source = 'market_row',
  });

  final String bottleId;

  /// Analytics source of the tap.
  final String source;

  static const double size = 28;

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistController.to;
    return Obx(() {
      final wanted = wishlist.isWanted(bottleId);
      return AppPressable(
        onTap: () => wishlist.toggle(bottleId, source: source),
        haptic: PressHaptic.selection,
        scale: 0.85,
        semanticLabel: wanted ? 'Remove from wishlist' : 'Add to wishlist',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.black.withValues(alpha: 0.55),
            border: Border.all(
              color: wanted
                  ? AppColors.tagGoldBorder
                  : AppColors.white.withValues(alpha: 0.12),
            ),
          ),
          child: AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.fast),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              wanted ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              key: ValueKey(wanted),
              size: 16,
              color: wanted ? AppColors.goldBright : AppColors.textMuted,
            ),
          ),
        ),
      );
    });
  }
}
