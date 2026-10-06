import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/bottle_image.dart';
import '../../../core/widgets/price_sparkline.dart';
import '../../../data/models/price_sparkline.dart';

/// One bottle on a Home list, on its own card like a Collection row: art,
/// name and a caption on the left, its 90-day price line in the middle, and
/// the price with its change on the right. Shared by the movers, the
/// collection's movers and the community lists, so every Home row reads the
/// same. Lay a list out with [spaced].
class DashboardBottleRow extends StatelessWidget {
  const DashboardBottleRow({
    super.key,
    required this.name,
    required this.imageUrls,
    required this.heroId,
    required this.price,
    required this.change,
    required this.caption,
    required this.sparkline,
    required this.onTap,
  });

  final String name;
  final List<String> imageUrls;

  /// The bottle id when this row owns the art's Hero, else null.
  final String? heroId;

  /// Formatted price, or null for "No price yet".
  final String? price;

  /// Percent change over the window; null hides it.
  final double? change;
  final String? caption;

  /// Null while loading: the view draws a dashed baseline meanwhile.
  final PriceSparkline? sparkline;
  final VoidCallback? onTap;

  static const double _art = 48;

  /// Gap between two row cards.
  static const double gap = AppSpacing.xs;

  /// [rows] with [gap] between them.
  static List<Widget> spaced(Iterable<Widget> rows) => [
    for (final (i, row) in rows.indexed) ...[
      if (i > 0) const SizedBox(height: gap),
      row,
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final meta = AppTextStyles.bodyS().copyWith(
      fontSize: 11,
      color: AppColors.textWolf,
    );
    final change = this.change;

    return AppPressable(
      onTap: onTap,
      haptic: PressHaptic.tap,
      child: AppCard(
        radius: AppRadii.md,
        showBorder: false,
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox.square(
                dimension: _art,
                child: BottleImage(
                  urls: imageUrls,
                  bottleId: heroId,
                  cacheWidthPx: 132,
                  padding: const EdgeInsets.all(3),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: caption == null ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyM().copyWith(
                      height: 1.2,
                      color: AppColors.white,
                    ),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: meta,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            PriceSparklineView(data: sparkline, width: 60, height: 24),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price ?? 'No price',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: price == null
                        ? meta
                        : AppTextStyles.bodyM().copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textCream,
                          ),
                  ),
                  if (change != null)
                    Text(
                      PriceFormatter.percentLabel(change),
                      maxLines: 1,
                      style: AppTextStyles.bodyS().copyWith(
                        fontWeight: FontWeight.w600,
                        color: PriceFormatter.percentColor(change),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
