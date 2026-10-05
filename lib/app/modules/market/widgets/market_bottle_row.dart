import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../core/analytics/app_analytics_controller.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_image_url.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/utils/proof_formatter.dart';
import '../../../core/utils/rating_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/bottle_image.dart';
import '../../../core/widgets/bottle_meta_chip.dart';
import '../../../core/widgets/price_sparkline.dart';
import '../../../core/widgets/pricing_badge.dart';
import '../../../data/models/bluebook_model.dart';
import '../../../data/models/price_sparkline.dart';
import '../../../routes/app_routes.dart';

/// One bottle in the benchmark list: art, name, distillery and region, type /
/// age / ABV chips and rating on the left; price, what it rests on, a 90-day
/// sparkline, movement and range on the right. Tapping opens the bottle, its
/// art flying across.
class MarketBottleRow extends StatelessWidget {
  const MarketBottleRow({super.key, required this.bottle, this.sparkline});

  final BluebookModel bottle;

  /// 90-day price line; null while loading or when there is no history.
  final PriceSparkline? sparkline;

  void _open() {
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(
        AppAnalyticsController.to.logTap('market_benchmark_open', {
          'bottle_id': bottle.id,
        }),
      );
    }
    Get.toNamed(
      AppRoutes.benchmarkDetail,
      arguments: {
        'id': bottle.id,
        'name': bottle.bottleName,
        'image': bottle.image,
        'average': bottle.average,
        'low': bottle.low,
        'high': bottle.high,
        'proof': bottle.proof,
        'description': bottle.description,
        'rating': bottle.rating,
        'price_movement': bottle.priceMovement,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = AppTextStyles.bodyS().copyWith(
      fontSize: 11,
      color: AppColors.textWolf,
    );
    final movementColor = PriceFormatter.priceMovementColor(
      bottle.priceMovement,
    );
    final details = bottle.details;
    // Who made it and where, then type / age / ABV (proof when the catalog has
    // no ABV) as chips. Whatever the catalog doesn't know is left out.
    final origin = [
      details.distillery ?? details.brand,
      details.region,
    ].whereType<String>().join(' · ');
    final chips = [
      ?details.spiritType,
      ?details.ageLabel,
      ?(details.abvLabel ?? ProofFormatter.formatLabel(bottle.proof)),
    ];
    // Most of the catalog has no price yet; say so instead of "$0".
    final priced = (double.tryParse(bottle.average ?? '') ?? 0) > 0;

    return AppPressable(
      onTap: _open,
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
                dimension: 66,
                child: BottleImage(
                  url: AppImageUrl.resolve(bottle.image),
                  bottleId: bottle.id,
                  cacheWidthPx: 200,
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
                    bottle.bottleName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyL().copyWith(
                      fontSize: 15,
                      height: 1.2,
                      color: AppColors.white,
                    ),
                  ),
                  if (origin.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      origin,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: meta.copyWith(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final label in chips) BottleMetaChip(label: label),
                      if (bottle.isRare == true)
                        const BottleMetaChip(label: 'Rare', gold: true),
                      if (details.isAllocated)
                        const BottleMetaChip(label: 'Allocated', gold: true),
                      if (RatingFormatter.outOfTen(bottle.rating) != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              AppAssets.star,
                              width: 9,
                              height: 9,
                              colorFilter: const ColorFilter.mode(
                                AppColors.textWolf,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              RatingFormatter.label(bottle.rating),
                              style: meta,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!priced)
                  Text('No price yet', style: meta)
                else ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PricingBadge(pricing: bottle.pricing, compact: true),
                      const SizedBox(width: 6),
                      Text(
                        PriceFormatter.format(bottle.average),
                        style: AppTextStyles.bodyL().copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textCream,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  PriceSparklineView(data: sparkline, width: 60, height: 20),
                  const SizedBox(height: 4),
                  Text(
                    PriceFormatter.formatPriceMovementLabel(
                      bottle.priceMovement,
                    ),
                    style: AppTextStyles.bodyS().copyWith(
                      color: movementColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${PriceFormatter.format(bottle.low)} – '
                    '${PriceFormatter.format(bottle.high)}',
                    style: meta.copyWith(fontSize: 10),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
