import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../data/models/bluebook_price_history_chart_model.dart';
import '../../home/widgets/home_value_chart.dart' show chartCrosshairIndicators;
import '../benchmark_detail_controller.dart';

FlLine _dottedGridLine(double _) => FlLine(
  color: AppColors.chartGridLine,
  strokeWidth: 0.7,
  dashArray: const [3, 4],
);

/// The bottle's price over the selected range.
///
/// History is change-only: each point is the day the price moved, plus the
/// price in force at each end of the range. So the x axis is real days, not
/// point index, and the line is a step — the price holds until the next
/// point rather than drifting towards it.
///
/// Switching range keeps the old line on screen (dimmed, with a thin
/// progress bar) and tweens to the new one, instead of a spinner.
class BenchmarkPriceChart extends GetView<BenchmarkDetailController> {
  const BenchmarkPriceChart({super.key});

  static const double height = 218;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Obx(() {
        final loading = controller.chartLoading.value;
        final pts = controller.chartPoints.toList(growable: false);
        final error = controller.chartError.value;

        if (pts.isEmpty) {
          if (loading) {
            return const ShimmerBox(
              height: height,
              width: double.infinity,
              radius: 0,
            );
          }
          return _EmptyChart(
            message: error != null
                ? 'Could not load the price history.'
                : 'No price history for this range yet.',
            onRetry: error != null ? controller.fetchPriceChart : null,
          );
        }

        return Stack(
          children: [
            AnimatedOpacity(
              opacity: loading ? 0.45 : 1,
              duration: AppMotion.of(context, AppMotion.fast),
              child: _Chart(
                points: pts,
                bsmi: controller.chartBsmiValues.toList(growable: false),
                marketLabel: controller.marketSeriesLabel,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: AnimatedOpacity(
                opacity: loading ? 1 : 0,
                duration: AppMotion.of(context, AppMotion.fast),
                child: const LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.chartPlotBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.show_chart_rounded,
              size: 28,
              color: AppColors.textWolf,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.caption().copyWith(
                color: AppColors.textWolf,
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({
    required this.points,
    required this.bsmi,
    required this.marketLabel,
  });

  final List<BluebookPriceChartPoint> points;

  /// Same length as [points], or empty when there is no benchmark series.
  final List<double> bsmi;
  final String marketLabel;

  @override
  Widget build(BuildContext context) {
    final start = points.first.date;
    double xOf(DateTime d) => d.difference(start).inHours / 24;

    final spots = [for (final p in points) FlSpot(xOf(p.date), p.price)];
    // One point (or all on one day) still draws a visible flat line.
    if (spots.length == 1 || spots.last.x == spots.first.x) {
      spots.add(FlSpot(spots.first.x + 1, spots.last.y));
    }

    final hasBsmi = bsmi.length == points.length && bsmi.isNotEmpty;
    final bsmiSpots = hasBsmi
        ? [
            for (var i = 0; i < points.length; i++)
              FlSpot(xOf(points[i].date), bsmi[i]),
          ]
        : const <FlSpot>[];

    final ys = [...points.map((e) => e.price), if (hasBsmi) ...bsmi];
    var minY = ys.reduce(math.min);
    var maxY = ys.reduce(math.max);
    if (minY == maxY) {
      final pad = math.max(1.0, minY.abs() * 0.1);
      minY -= pad;
      maxY += pad;
    } else {
      final pad = (maxY - minY) * 0.12;
      minY -= pad;
      maxY += pad;
    }

    final maxX = math.max(spots.last.x, 1.0);
    final hInterval = (maxY - minY) / 4;
    final vInterval = maxX / 4;

    String dateAt(double x) => DateFormat(
      'MMM d',
    ).format(start.add(Duration(hours: (x * 24).round())));

    LineChartBarData series(List<FlSpot> s, Color color, Gradient area) =>
        LineChartBarData(
          spots: s,
          color: color,
          barWidth: 2,
          isStepLineChart: true,
          lineChartStepData: const LineChartStepData(
            stepDirection: LineChartStepData.stepDirectionForward,
          ),
          dotData: FlDotData(
            show: s.length <= 8,
            getDotPainter: (spot, percent, bar, index) =>
                FlDotCirclePainter(radius: 3, color: color),
          ),
          belowBarData: BarAreaData(show: true, gradient: area),
        );

    return Padding(
      // Room for the last point's dot and the step up at the right edge.
      padding: const EdgeInsets.only(right: 12),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          // The screen where a user most wants exact values: scrub with a
          // crosshair readout.
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: chartCrosshairIndicators,
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) => AppColors.chartTooltipSurface,
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              getTooltipItems: (touched) => touched.map((spot) {
                final isBsmi = hasBsmi && spot.barIndex == 1;
                final color = isBsmi
                    ? AppColors.chartLineBsmi
                    : AppColors.chartLineMarketValue;
                final label = isBsmi ? 'BSMI' : marketLabel;
                final date = DateFormat(
                  'MMM d, yyyy',
                ).format(start.add(Duration(hours: (spot.x * 24).round())));
                return LineTooltipItem(
                  '$date\n$label: ${PriceFormatter.format(spot.y.round().toString())}',
                  AppTextStyles.caption().copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
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
                reservedSize: 46,
                interval: hInterval > 0 ? hInterval : 1,
                getTitlesWidget: (value, meta) {
                  // The padded min / max land between interval labels and
                  // would crowd them.
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(
                      PriceFormatter.format(value.round().toString()),
                      style: AppTextStyles.micro(),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: vInterval > 0 ? vInterval : 1,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  space: 4,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                  child: Text(dateAt(value), style: AppTextStyles.micro()),
                ),
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              for (final y in [minY, maxY])
                HorizontalLine(
                  y: y,
                  color: AppColors.chartGridLine,
                  strokeWidth: 1,
                  dashArray: const [3, 4],
                ),
            ],
          ),
          gridData: FlGridData(
            horizontalInterval: hInterval > 0 ? hInterval : 1,
            verticalInterval: vInterval > 0 ? vInterval : 1,
            getDrawingHorizontalLine: _dottedGridLine,
            getDrawingVerticalLine: _dottedGridLine,
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            series(
              spots,
              AppColors.chartLineMarketValue,
              AppColors.chartMarketValueArea,
            ),
            if (hasBsmi)
              series(
                bsmiSpots,
                AppColors.chartLineBsmi,
                AppColors.chartBsmiArea,
              ),
          ],
          backgroundColor: AppColors.chartPlotBackground,
        ),
        duration: AppMotion.of(context, AppMotion.chartReflow),
        curve: AppMotion.emphasizedDecelerate,
      ),
    );
  }
}

/// "Market Value" (or "Oak Spire price") and, when present, "BSMI".
class BenchmarkChartLegend extends GetView<BenchmarkDetailController> {
  const BenchmarkChartLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasBsmi = controller.chartBsmiValues.isNotEmpty;
      return Row(
        children: [
          _LegendItem(
            color: AppColors.chartLineMarketValue,
            label: controller.marketSeriesLabel,
          ),
          if (hasBsmi) ...[
            const SizedBox(width: 22),
            const _LegendItem(color: AppColors.chartLineBsmi, label: 'BSMI'),
          ],
        ],
      );
    });
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.bodyM()),
      ],
    );
  }
}
