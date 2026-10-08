import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_image_url.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/bottle_image.dart';
import '../../../core/widgets/price_sparkline.dart';
import '../../../data/models/price_sparkline.dart';
import '../../../data/models/wishlist_item.dart';

String _money(double v) => PriceFormatter.format(v.round().toString());

/// "Added at $199 · now $212", or what is known of it.
String wishlistPriceLine(WishlistItem item) {
  final from = item.addedPrice, now = item.currentPrice;
  if (now == null) return 'No market price yet';
  if (from == null) return 'Now ${_money(now)}';
  return 'Added at ${_money(from)} · now ${_money(now)}';
}

/// "At your target $60", "Target $185 · 13% away", or null without a target.
String? wishlistTargetLabel(WishlistItem item) {
  final target = item.targetPrice;
  if (target == null) return null;
  if (item.atTarget) return 'At your target ${_money(target)}';
  final above = item.aboveTargetPercent;
  if (above == null) return 'Target ${_money(target)}';
  return 'Target ${_money(target)} · ${above.round()}% away';
}

/// One wishlist bottle on its own card: art, name, the price when added and
/// now, the target; on the right its 90-day line and the move since added.
class WishlistRow extends StatelessWidget {
  const WishlistRow({
    super.key,
    required this.item,
    required this.sparkline,
    required this.onTap,
    this.heroId,
  });

  final WishlistItem item;
  final PriceSparkline? sparkline;
  final VoidCallback onTap;

  /// The bottle id when this row owns the art's Hero.
  final String? heroId;

  @override
  Widget build(BuildContext context) {
    final meta = AppTextStyles.bodyS().copyWith(
      fontSize: 11,
      color: AppColors.textWolf,
    );
    final target = wishlistTargetLabel(item);
    final change = item.changeSinceAdded;

    return AppPressable(
      onTap: onTap,
      haptic: PressHaptic.tap,
      child: AppCard(
        radius: AppRadii.md,
        showBorder: false,
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox.square(
                dimension: 56,
                child: BottleImage(
                  url: AppImageUrl.resolve(item.bottle.image),
                  bottleId: heroId,
                  cacheWidthPx: 168,
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.bottle.bottleName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyL().copyWith(
                      fontSize: 15,
                      height: 1.2,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(wishlistPriceLine(item), style: meta),
                  if (target != null) ...[
                    const SizedBox(height: 5),
                    WishlistTargetChip(label: target, met: item.atTarget),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PriceSparklineView(data: sparkline, width: 60, height: 22),
                const SizedBox(height: 5),
                Text(
                  change == null ? '—' : PriceFormatter.percentLabel(change),
                  style: AppTextStyles.bodyS().copyWith(
                    fontWeight: FontWeight.w600,
                    color: PriceFormatter.percentColor(change),
                  ),
                ),
                Text('since added', style: meta.copyWith(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The target as a pill: green once the price reaches it.
class WishlistTargetChip extends StatelessWidget {
  const WishlistTargetChip({super.key, required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: met
            ? AppColors.trendPositive.withValues(alpha: 0.16)
            : AppColors.surfaceChip,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(
          color: met ? AppColors.trendPositive : AppColors.tagGoldBorder,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodyS().copyWith(
          fontSize: 11,
          color: met ? AppColors.textNeutralSoft : AppColors.goldBright,
        ),
      ),
    );
  }
}
