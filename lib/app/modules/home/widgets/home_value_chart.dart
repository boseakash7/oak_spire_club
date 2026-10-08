import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../core/utils/price_formatter.dart';
import '../home_controller.dart';

final _indexLevel = NumberFormat('#,##0.0', 'en_US');

String _pctLabel(double pct) =>
    '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';

/// The collection's value against the Oak Spire Index, both rebased to 100
/// at the start of the range: smooth lines that never overshoot a point
/// (history moves in steps), a dashed "start" baseline, and a soft gold wash
/// under the collection. No axes, grid or dots; the scoreboard above it and
/// the touch tooltip carry the numbers. Drawn on the card it sits in, so it
/// paints no background.
class HomeValueChart extends StatefulWidget {
  const HomeValueChart({super.key, this.height = 210});

  final double height;

  @override
  State<HomeValueChart> createState() => _HomeValueChartState();
}

class _HomeValueChartState extends State<HomeValueChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drawController;
  var _lastAnimatedRevision = -1;
  int? _pendingDrawRevision;

  @override
  void initState() {
    super.initState();
    _drawController =
        AnimationController(vsync: this, duration: AppMotion.chartDraw)
          ..addListener(() {
            if (mounted) setState(() {});
          });
  }

  @override
  void dispose() {
    _drawController.dispose();
    super.dispose();
  }

  void _scheduleDrawReplay(int revision) {
    if (_lastAnimatedRevision == revision || _pendingDrawRevision == revision) {
      return;
    }
    _pendingDrawRevision = revision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingDrawRevision = null;
      if (!mounted) return;
      _lastAnimatedRevision = revision;
      if (AppMotion.reduced(context)) {
        _drawController.value = 1;
      } else {
        _drawController.forward(from: 0);
      }
    });
  }

  /// Sweeps left → right from [minY] (bottom anchor) to each spot's target [y].
  static List<FlSpot> _spotsWithDrawProgress({
    required List<FlSpot> spots,
    required double minY,
    required double progress,
  }) {
    if (spots.isEmpty || progress >= 1) return spots;
    if (progress <= 0) {
      return [for (final s in spots) FlSpot(s.x, minY)];
    }

    final maxX = spots.last.x;
    final edge = progress * (maxX + 1);
    return [
      for (final s in spots)
        FlSpot(s.x, minY + (s.y - minY) * ((edge - s.x).clamp(0.0, 1.0))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Obx(() {
        final series = home.chartSeriesK.toList(growable: false);
        final loading = home.chartLoading.value;

        if (series.isEmpty) {
          if (_lastAnimatedRevision != -1) {
            _lastAnimatedRevision = -1;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _drawController.reset();
            });
          }
          if (loading) {
            return const ShimmerBox(
              height: double.infinity,
              width: double.infinity,
              radius: 8,
            );
          }
          return SizedBox.expand(
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
                    'No price history for this range yet',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.textWolf,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final bsmi = home.chartIndexSeriesK.toList(growable: false);
        final indexName = home.chartIndexName.value;
        final dates = home.chartPointDates.toList(growable: false);
        final marketPrices = home.chartMarketPrices.toList(growable: false);
        final bsmiPrices = home.chartIndexPrices.toList(growable: false);
        final minY = home.chartMinY.value;
        final maxY = home.chartMaxYk.value;
        _scheduleDrawReplay(home.chartRevision.value);
        final drawT = AppMotion.chart.transform(_drawController.value);

        final targetSpots = <FlSpot>[
          for (var i = 0; i < series.length; i++)
            FlSpot(i.toDouble(), series[i]),
        ];
        if (targetSpots.length == 1) {
          targetSpots.add(FlSpot(1, targetSpots.first.y));
        }
        final spots = _spotsWithDrawProgress(
          spots: targetSpots,
          minY: minY,
          progress: drawT,
        );

        final targetBsmiSpots = <FlSpot>[];
        if (bsmi.length == series.length) {
          for (var i = 0; i < bsmi.length; i++) {
            targetBsmiSpots.add(FlSpot(i.toDouble(), bsmi[i]));
          }
          if (targetBsmiSpots.length == 1) {
            targetBsmiSpots.add(FlSpot(1, targetBsmiSpots.first.y));
          }
        }
        final bsmiSpots = _spotsWithDrawProgress(
          spots: targetBsmiSpots,
          minY: minY,
          progress: drawT,
        );

        final maxX = math.max(
          spots.isEmpty ? 1.0 : spots.last.x,
          bsmiSpots.isEmpty ? 0.0 : bsmiSpots.last.x,
        );
        final maxXSafe = math.max(maxX, 1.0);
        // Room above and below so end dots and the baseline aren't clipped.
        final pad = math.max((maxY - minY) * 0.08, 0.5);
        final lo = math.min(minY, 100.0) - pad;
        final hi = math.max(maxY, 100.0) + pad;

        final chart = LineChart(
          LineChartData(
            minX: 0,
            maxX: maxXSafe,
            minY: lo,
            maxY: hi,
            backgroundColor: Colors.transparent,
            // No value or date labels: the scoreboard and the touch tooltip
            // carry the numbers, and the plot gets the full width.
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            clipData: const FlClipData.all(),
            // Where both lines start (100): above it is a gain.
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: 100,
                  color: AppColors.chartGridLine,
                  strokeWidth: 1,
                  dashArray: const [3, 4],
                ),
              ],
            ),
            gridData: const FlGridData(show: false),
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
                getTooltipItems: (touchedSpots) {
                  // fl_chart wants one item per touched line; the first
                  // carries the date.
                  return [
                    for (final (k, spot) in touchedSpots.indexed)
                      () {
                        final i = spot.x.round().clamp(0, series.length - 1);
                        final isIndex =
                            spot.barIndex == 1 &&
                            bsmiPrices.length == series.length;
                        final pct = (isIndex ? bsmi[i] : series[i]) - 100;
                        final value = isIndex
                            ? _indexLevel.format(bsmiPrices[i])
                            : PriceFormatter.format(
                                (i < marketPrices.length ? marketPrices[i] : 0)
                                    .round()
                                    .toString(),
                              );
                        final label = isIndex ? indexName : 'Your collection';
                        final color = isIndex
                            ? AppColors.chartLineBsmi
                            : AppColors.chartLineMarketValue;
                        final style = AppTextStyles.caption().copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        );
                        return LineTooltipItem(
                          k == 0
                              ? '${formatChartTooltipDate(i < dates.length ? dates[i] : '')}\n'
                              : '',
                          AppTextStyles.caption().copyWith(
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.left,
                          children: [
                            TextSpan(text: '$label: $value ', style: style),
                            TextSpan(
                              text: _pctLabel(pct),
                              style: style.copyWith(
                                color: PriceFormatter.percentColor(pct),
                              ),
                            ),
                          ],
                        );
                      }(),
                  ];
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                // Smooth, but clamped at each point so a step in the
                // history can't swing the curve past it.
                isCurved: true,
                curveSmoothness: 0.3,
                preventCurveOverShooting: true,
                color: AppColors.chartLineMarketValue,
                barWidth: 2.2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  cutOffY: lo,
                  applyCutOffY: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.chartLineMarketValue.withValues(alpha: 0.20),
                      AppColors.chartLineMarketValue.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              if (bsmiSpots.isNotEmpty)
                LineChartBarData(
                  spots: bsmiSpots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  preventCurveOverShooting: true,
                  color: AppColors.chartLineBsmi,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                ),
            ],
          ),
          // Line sweep is driven by [_drawController]; avoid double-lerp.
          duration: Duration.zero,
        );

        // A range switch dims the existing line and lets the new one sweep in,
        // rather than covering the plot with a spinner.
        return AnimatedOpacity(
          opacity: loading ? 0.4 : 1,
          duration: AppMotion.of(context, AppMotion.fast),
          curve: AppMotion.standard,
          child: chart,
        );
      }),
    );
  }
}

/// Gold crosshair plus an enlarged dot for the scrubbed point.
/// Shared with the benchmark detail chart.
List<TouchedSpotIndicatorData?> chartCrosshairIndicators(
  LineChartBarData bar,
  List<int> indexes,
) {
  return indexes.map((_) {
    return TouchedSpotIndicatorData(
      const FlLine(
        color: AppColors.chartCrosshair,
        strokeWidth: 1,
        dashArray: [3, 3],
      ),
      FlDotData(
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 4,
          color: barData.color ?? AppColors.chartLineMarketValue,
          strokeWidth: 2,
          strokeColor: AppColors.chartPlotBackground,
        ),
      ),
    );
  }).toList();
}

/// Tooltip date label, shared with the benchmark detail chart.
String formatChartTooltipDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '—';
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return trimmed;
  return DateFormat('MMM d, yyyy').format(parsed);
}
