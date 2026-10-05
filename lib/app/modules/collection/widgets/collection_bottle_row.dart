import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/utils/proof_formatter.dart';
import '../../../core/utils/rating_formatter.dart';
import '../../../core/widgets/animated_fill_bar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/bottle_image.dart';
import '../../../core/widgets/bottle_meta_chip.dart';
import '../../../core/widgets/price_sparkline.dart';
import '../../../core/widgets/pricing_badge.dart';
import '../../../data/models/collection_item_display.dart';
import '../../../data/models/collection_item_model.dart';
import '../../../data/models/price_sparkline.dart';

/// One bottle in the collection list.
///
/// Left: art, name, maker and region, type / age / ABV / rating chips, how
/// full it is and what was paid. Right: what it is worth today, the gain
/// against what was paid, its 90-day sparkline and its last price move.
/// Presses scale it; [heroBottleId] lets its art fly to the detail screen.
class CollectionBottleRow extends StatelessWidget {
  const CollectionBottleRow({
    super.key,
    required this.item,
    required this.onTap,
    this.heroBottleId,
    this.sparkline,
  });

  final CollectionItemModel item;
  final VoidCallback onTap;

  /// Null when another row on screen already uses this bottle's Hero tag.
  final String? heroBottleId;

  /// Null while loading, or when the bottle has no price history.
  final PriceSparkline? sparkline;

  @override
  Widget build(BuildContext context) {
    final meta = AppTextStyles.bodyS().copyWith(
      fontSize: 11,
      color: AppColors.textWolf,
    );
    final details = item.details;
    final origin = [
      details.distillery ?? details.brand,
      details.region,
    ].whereType<String>().join(' · ');
    final chips = [
      ?details.spiritType,
      ?details.ageLabel,
      ?(details.abvLabel ?? ProofFormatter.formatLabel(item.proof)),
    ];
    final hasRating = RatingFormatter.outOfTen(item.ratingRaw) != null;
    final qty = item.displayQuantity;
    final paid = item.paidTotalValue;

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
                dimension: 66,
                child: BottleImage(
                  urls: item.resolvedImageCandidates,
                  bottleId: heroBottleId,
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
                    item.lineTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyL().copyWith(
                      fontSize: 15,
                      height: 1.2,
                      color: AppColors.white,
                    ),
                  ),
                  if (origin.isNotEmpty) ...[
                    const SizedBox(height: 3),
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
                  if (chips.isNotEmpty || item.isRareFind || hasRating) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final label in chips) BottleMetaChip(label: label),
                        if (item.isRareFind)
                          const BottleMetaChip(label: 'Rare', gold: true),
                        if (hasRating)
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
                                RatingFormatter.label(item.ratingRaw),
                                style: meta,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: AnimatedFillBar(value: item.fillRatio, height: 6),
                      ),
                      const SizedBox(width: 6),
                      Text('${(item.fillRatio * 100).round()}%', style: meta),
                      if (qty > 1) ...[
                        const SizedBox(width: 6),
                        Text('×$qty', style: meta),
                      ],
                      if (paid > 0) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Paid ${_dollars(paid)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: meta,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _ValueColumn(item: item, sparkline: sparkline, meta: meta),
          ],
        ),
      ),
    );
  }
}

/// Today's value, gain against paid, sparkline and last move. A bottle with
/// no market price shows what was paid, marked as such.
class _ValueColumn extends StatelessWidget {
  const _ValueColumn({
    required this.item,
    required this.sparkline,
    required this.meta,
  });

  final CollectionItemModel item;
  final PriceSparkline? sparkline;
  final TextStyle meta;

  @override
  Widget build(BuildContext context) {
    final market = item.marketTotalValue;
    final valueStyle = AppTextStyles.bodyL().copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.textCream,
    );

    if (market == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            item.paidTotalValue > 0 ? _dollars(item.paidTotalValue) : '—',
            style: valueStyle,
          ),
          const SizedBox(height: 4),
          Text('Valued at cost', style: meta.copyWith(fontSize: 10)),
        ],
      );
    }

    final gain = item.gainValue;
    final pct = item.gainPercent;
    final gainColor = gain == null
        ? AppColors.textWolf
        : gain > 0
        ? AppColors.trendPositive
        : gain < 0
        ? AppColors.marketTrendDown
        : AppColors.textWolf;
    final movement = item.priceMovementRaw;
    final movementLabel = PriceFormatter.formatPriceMovementLabel(movement);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.pricing != null) ...[
                PricingBadge(pricing: item.pricing, compact: true),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_dollars(market), style: valueStyle),
                ),
              ),
            ],
          ),
          if (gain != null && pct != null) ...[
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${gain >= 0 ? '+' : '-'}${_dollars(gain.abs())} '
                '(${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%)',
                style: AppTextStyles.bodyS().copyWith(
                  fontSize: 11,
                  color: gainColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 5),
          PriceSparklineView(data: sparkline, width: 64, height: 22),
          if (movementLabel != '—') ...[
            const SizedBox(height: 3),
            Text(
              'Last $movementLabel',
              style: meta.copyWith(
                fontSize: 10,
                color: PriceFormatter.priceMovementColor(movement),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _dollars(double v) => PriceFormatter.format(v.toStringAsFixed(2));
