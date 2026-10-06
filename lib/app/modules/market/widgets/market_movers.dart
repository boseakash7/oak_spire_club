import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_segmented_range.dart';
import '../market_controller.dart';
import 'market_bottle_row.dart';

/// "Biggest movers": the bottles that rose (or fell) most over the window,
/// with a rising / falling toggle and a link that sorts the full list the
/// same way. Absent when the server sends no overview.
class MarketMovers extends GetView<MarketController> {
  const MarketMovers({super.key});

  /// Rows shown here; "See all" sorts the list below for the rest.
  static const int _shown = 5;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final overview = controller.overview.value;
      if (overview == null) return const SizedBox.shrink();
      final direction = controller.moversDirection.value;
      final rows = controller.movers.take(_shown).toList(growable: false);

      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biggest movers',
                        style: AppTextStyles.titleS().copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Last ${overview.windowDays} days',
                        style: AppTextStyles.bodyS().copyWith(
                          fontSize: 11,
                          color: AppColors.textWolf,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSegmentedRange<MoversDirection>(
                  values: MoversDirection.values,
                  selected: direction,
                  segmentWidth: 64,
                  labelOf: (d) =>
                      d == MoversDirection.gainers ? 'Rising' : 'Falling',
                  onChanged: controller.setMoversDirection,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.stateSwitch),
              child: rows.isEmpty
                  ? Padding(
                      key: ValueKey('empty-$direction'),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        direction == MoversDirection.gainers
                            ? 'No bottle has risen in this window yet.'
                            : 'No bottle has fallen in this window yet.',
                        style: AppTextStyles.bodyM().copyWith(
                          color: AppColors.textWolf,
                        ),
                      ),
                    )
                  : Column(
                      key: ValueKey('rows-$direction'),
                      children: [
                        for (final b in rows)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Obx(
                              () => MarketBottleRow(
                                bottle: b,
                                sparkline: controller.sparklines[b.id],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            if (rows.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => controller.setSort(
                    direction == MoversDirection.gainers
                        ? MarketSort.gain30d
                        : MarketSort.loss30d,
                  ),
                  child: Text(
                    'See all in the list below',
                    style: AppTextStyles.bodyS().copyWith(
                      color: AppColors.goldBright,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
