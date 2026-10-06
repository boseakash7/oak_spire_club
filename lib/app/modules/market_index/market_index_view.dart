import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/animations/app_motion.dart';
import '../../core/animations/staggered_entrance.dart';
import '../../core/platform/app_platform.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/price_formatter.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_segmented_range.dart';
import '../../core/widgets/shimmer_box.dart';
import '../../data/models/bluebook_model.dart';
import '../../data/models/market_models.dart';
import '../home/widgets/home_value_chart.dart' show chartCrosshairIndicators;
import '../market/widgets/market_bottle_row.dart';
import 'market_index_controller.dart';

const double _kInset = AppSpacing.gutter;
final _indexValue = NumberFormat('#,##0.0', 'en_US');

/// One Oak Spire index: level and change, the chart for 1M–1Y, the bottles
/// that rose and fell most, and how it is built.
class MarketIndexView extends GetView<MarketIndexController> {
  const MarketIndexView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDeep,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDeep,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: AppBackButton(onPressed: () => Get.back<void>()),
        titleSpacing: 0,
        title: Obx(
          () => Text(
            controller.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleM().copyWith(color: AppColors.textCream),
          ),
        ),
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () => controller.load(forceRefresh: true),
        child: Obx(() {
          final d = controller.detail.value;
          if (d == null && controller.loadFailed.value) {
            return ListView(
              physics: AppPlatform.scrollPhysics,
              children: [
                const SizedBox(height: 120),
                AppEmptyState(
                  icon: Icons.show_chart_rounded,
                  title: 'Couldn\'t load this index',
                  message: 'Check your connection and try again.',
                  actionLabel: 'Retry',
                  onAction: controller.load,
                ),
              ],
            );
          }
          return ListView(
            physics: AppPlatform.scrollPhysics,
            // An explicit padding drops the ListView's own safe-area
            // padding, so clear Android's navigation bar here.
            padding: EdgeInsets.fromLTRB(
              0,
              AppSpacing.xs,
              0,
              40 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: _kInset),
                child: FadeSlideEntrance(child: _Headline()),
              ),
              const SizedBox(height: AppSpacing.lg),
              const FadeSlideEntrance(index: 1, child: _IndexChart()),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _kInset),
                // A ListView stretches its children; the control has a fixed
                // width, so let it sit at the left.
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Obx(
                    () => AppSegmentedRange<MarketIndexRange>(
                      values: MarketIndexRange.values,
                      selected: controller.range.value,
                      labelOf: (r) => r.label,
                      onChanged: (r) => unawaited(controller.setRange(r)),
                    ),
                  ),
                ),
              ),
              if (d != null) ...[
                const SizedBox(height: AppSpacing.xl),
                _Movers(
                  title: 'Biggest risers',
                  windowDays: d.contributorsWindowDays,
                  bottles: d.risers,
                  empty: 'No bottle in this index has risen yet.',
                ),
                _Movers(
                  title: 'Biggest fallers',
                  windowDays: d.contributorsWindowDays,
                  bottles: d.fallers,
                  empty: 'No bottle in this index has fallen yet.',
                ),
                _HowItWorks(detail: d),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _Headline extends GetView<MarketIndexController> {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.detail.value?.index;
      if (index == null) {
        return const ShimmerScope(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(height: 30, width: 140),
              SizedBox(height: 8),
              ShimmerBox(height: 14, width: 200),
            ],
          ),
        );
      }
      final change = controller.rangeChange;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _indexValue.format(index.value),
                style: AppTextStyles.headingM().copyWith(
                  fontSize: 32,
                  height: 1.1,
                  color: AppColors.textCream,
                ),
              ),
              const SizedBox(width: 10),
              if (change != null)
                Text(
                  '${PriceFormatter.percentLabel(change)} '
                  '${controller.range.value.label}',
                  style: AppTextStyles.bodyL().copyWith(
                    fontWeight: FontWeight.w600,
                    color: PriceFormatter.percentColor(change),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (index.change1d != null)
                '${PriceFormatter.percentLabel(index.change1d!)} today',
              '${NumberFormat.decimalPattern('en_US').format(index.constituents)} bottles',
              if (index.asOf != null)
                'as of ${DateFormat('MMM d, yyyy').format(index.asOf!)}',
            ].join(' · '),
            style: AppTextStyles.bodyS().copyWith(color: AppColors.textWolf),
          ),
          if (index.stale) ...[
            const SizedBox(height: 4),
            Text(
              'This index hasn\'t updated for a few days.',
              style: AppTextStyles.bodyS().copyWith(
                color: AppColors.goldAccent,
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _IndexChart extends GetView<MarketIndexController> {
  const _IndexChart();

  static const double _height = 200;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Obx(() {
        final loading = controller.isLoading.value;
        final series =
            controller.detail.value?.index?.series ??
            const <MarketIndexPoint>[];
        if (series.length < 2) {
          if (loading) {
            return const ShimmerBox(
              height: _height,
              width: double.infinity,
              radius: 0,
            );
          }
          return Center(
            child: Text(
              'Not enough history for this range yet.',
              style: AppTextStyles.caption().copyWith(
                color: AppColors.textWolf,
              ),
            ),
          );
        }
        return AnimatedOpacity(
          opacity: loading ? 0.45 : 1,
          duration: AppMotion.of(context, AppMotion.fast),
          child: _Chart(series: series),
        );
      }),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.series});

  final List<MarketIndexPoint> series;

  @override
  Widget build(BuildContext context) {
    final start = series.first.date;
    double xOf(DateTime d) => d.difference(start).inHours / 24;
    final spots = [for (final p in series) FlSpot(xOf(p.date), p.value)];

    final ys = series.map((p) => p.value);
    var minY = ys.reduce(math.min);
    var maxY = ys.reduce(math.max);
    final pad = minY == maxY
        ? math.max(1.0, minY.abs() * 0.02)
        : (maxY - minY) * 0.15;
    minY -= pad;
    maxY += pad;
    final maxX = math.max(spots.last.x, 1.0);
    final up = series.last.value >= series.first.value;
    final color = up
        ? AppColors.chartLineMarketValue
        : AppColors.marketTrendDown;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: chartCrosshairIndicators,
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) => AppColors.chartTooltipSurface,
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItems: (touched) => touched.map((spot) {
                final date = DateFormat(
                  'MMM d, yyyy',
                ).format(start.add(Duration(hours: (spot.x * 24).round())));
                return LineTooltipItem(
                  '$date\n${_indexValue.format(spot.y)}',
                  AppTextStyles.caption().copyWith(
                    color: AppColors.textCream,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.chartGridLine,
              strokeWidth: 0.7,
              dashArray: [3, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: (maxY - minY) / 4,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(
                      NumberFormat('#,##0', 'en_US').format(value),
                      style: AppTextStyles.captionS().copyWith(
                        color: AppColors.textWolf,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: maxX / 3,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    DateFormat(
                      'MMM d',
                    ).format(start.add(Duration(hours: (value * 24).round()))),
                    style: AppTextStyles.captionS().copyWith(
                      color: AppColors.textWolf,
                    ),
                  ),
                ),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: color,
              barWidth: 2,
              isCurved: false,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: AppMotion.of(context, AppMotion.chartReflow),
      ),
    );
  }
}

class _Movers extends GetView<MarketIndexController> {
  const _Movers({
    required this.title,
    required this.windowDays,
    required this.bottles,
    required this.empty,
  });

  final String title;
  final int windowDays;
  final List<BluebookModel> bottles;
  final String empty;

  static const int _shown = 5;

  @override
  Widget build(BuildContext context) {
    final rows = bottles.take(_shown).toList(growable: false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kInset, 0, _kInset, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleS().copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'Last $windowDays days',
            style: AppTextStyles.bodyS().copyWith(
              fontSize: 11,
              color: AppColors.textWolf,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (rows.isEmpty)
            Text(
              empty,
              style: AppTextStyles.bodyM().copyWith(color: AppColors.textWolf),
            )
          else
            for (final b in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Obx(
                  () => MarketBottleRow(
                    bottle: b,
                    sparkline: controller.sparklines[b.id],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.detail});

  final MarketIndexDetail detail;

  @override
  Widget build(BuildContext context) {
    final description = detail.index?.description;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How this index works',
            style: AppTextStyles.titleS().copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description != null) ...[
                  Text(
                    description,
                    style: AppTextStyles.bodyM().copyWith(
                      height: 1.35,
                      color: AppColors.textNeutralSoft,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                for (final line in detail.methodology)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6, right: 8),
                          child: Icon(
                            Icons.circle,
                            size: 5,
                            color: AppColors.goldAccent,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            line,
                            style: AppTextStyles.bodyS().copyWith(
                              height: 1.4,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  'Prices describe the market. They are not investment advice.',
                  style: AppTextStyles.bodyS().copyWith(
                    fontSize: 11,
                    color: AppColors.textWolf,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
