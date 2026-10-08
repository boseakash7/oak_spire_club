import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_segmented_range.dart';
import '../../home/home_controller.dart';
import '../../home/widgets/home_value_chart.dart';

/// "You vs the market": a scoreboard card. Its header holds the range
/// (1M / 3M / 6M / 1Y), then the collection's and the Oak Spire Index's moves
/// over that range in big numbers, a chip saying how far ahead or behind the
/// collection is, and the chart of both lines. Everything follows the range.
class CollectionMarketChartCard extends StatelessWidget {
  const CollectionMarketChartCard({super.key});

  /// Under this many points apart the two read as level.
  static const double _levelBand = 0.05;

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    final caption = AppTextStyles.bodyS().copyWith(
      fontSize: 11,
      color: AppColors.textWolf,
    );

    // No padding of its own: the text sits in padded blocks, and the chart
    // between them runs to the card's left and right edges.
    return AppCard(
      child: Obx(() {
        final range = home.selectedChartRange.value;
        final mineSeries = home.chartSeriesK;
        final indexSeries = home.chartIndexSeriesK;
        final mine = mineSeries.isEmpty ? null : mineSeries.last - 100;
        final theirs = indexSeries.isEmpty ? null : indexSeries.last - 100;
        // Dim the figures while a new range loads, like the chart.
        final loading = home.chartLoading.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'You vs the market',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyS().copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      AppSegmentedRange<HomeChartRange>(
                        values: HomeChartRange.values,
                        selected: range,
                        segmentWidth: 34,
                        height: 28,
                        labelOf: (r) => r.label,
                        onChanged: (r) => unawaited(home.setChartRange(r)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AnimatedOpacity(
                    opacity: loading ? 0.45 : 1,
                    duration: const Duration(milliseconds: 180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _Score(
                                label: 'Your collection',
                                color: AppColors.chartLineMarketValue,
                                percent: mine,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _Score(
                                label: home.chartIndexName.value,
                                color: AppColors.chartLineBsmi,
                                percent: theirs,
                              ),
                            ),
                          ],
                        ),
                        if (mine != null && theirs != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _GapChip(gap: mine - theirs, levelBand: _levelBand),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const HomeValueChart(height: 150),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              child: Text(
                'Both start at 0% · touch the chart to compare',
                style: caption,
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// One side of the scoreboard: a swatch and name over the move in big type.
class _Score extends StatelessWidget {
  const _Score({
    required this.label,
    required this.color,
    required this.percent,
  });

  final String label;
  final Color color;
  final double? percent;

  @override
  Widget build(BuildContext context) {
    final pct = percent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyS().copyWith(
                  fontSize: 11,
                  color: AppColors.textWolf,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            pct == null ? '—' : _pct(pct),
            style: AppTextStyles.numberL().copyWith(
              fontSize: 22,
              color: pct == null
                  ? AppColors.textWolf
                  : PriceFormatter.percentColor(pct),
            ),
          ),
        ),
      ],
    );
  }
}

/// "Ahead of the market by 4.9 pts", "Behind … by …" or "Level with the
/// market": the gap between the two moves, in percentage points.
class _GapChip extends StatelessWidget {
  const _GapChip({required this.gap, required this.levelBand});

  final double gap;
  final double levelBand;

  @override
  Widget build(BuildContext context) {
    final level = gap.abs() < levelBand;
    final color = level
        ? AppColors.textMuted
        : PriceFormatter.percentColor(gap);
    final text = level
        ? 'Level with the market'
        : '${gap > 0 ? 'Ahead of' : 'Behind'} the market by '
              '${gap.abs().toStringAsFixed(1)} pts';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            level
                ? Icons.drag_handle_rounded
                : gap > 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.bodyS().copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

String _pct(double pct) => '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';
