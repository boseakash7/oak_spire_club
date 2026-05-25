import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/price_formatter.dart';
import '../home_controller.dart';

/// Horizontal inset from screen edge (parent cancels 23px content pad + this).
const double kHomeChartHorizontalInset = 2;

FlLine _homeDottedGridLine(double _) => FlLine(
  color: AppColors.chartGridLine,
  strokeWidth: 0.7,
  dashArray: const [3, 4],
);

/// Legend row below the home chart.
class HomeChartLegend extends StatelessWidget {
  const HomeChartLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendSwatch(
          color: AppColors.chartLineMarketValue,
          label: 'Market Value',
        ),
        const SizedBox(width: 22),
        _legendSwatch(color: AppColors.chartLineBsmi, label: 'BSMI'),
      ],
    );
  }

  Widget _legendSwatch({required Color color, required String label}) {
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
        Text(
          label,
          style: AppTextStyles.body16().copyWith(
            fontSize: 14,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}

class HomeValueChart extends StatefulWidget {
  const HomeValueChart({super.key});

  @override
  State<HomeValueChart> createState() => _HomeValueChartState();
}

class _HomeValueChartState extends State<HomeValueChart> {
  var _chartVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _chartVisible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    return AnimatedOpacity(
      opacity: _chartVisible ? 1 : 0,
      duration: AppMotion.medium,
      curve: AppMotion.enter,
      child: SizedBox(
        height: 188,
        width: double.infinity,
        child: Obx(() {
          final series = home.chartSeriesK.toList(growable: false);
          final loading = home.chartLoading.value;

          if (series.isEmpty) {
            return ColoredBox(
              color: AppColors.chartPlotBackground,
              child: loading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gold1,
                        ),
                      ),
                    )
                  : const Center(
                      child: Text(
                        'No chart data',
                        style: TextStyle(
                          color: AppColors.textWolf,
                          fontSize: 12,
                        ),
                      ),
                    ),
            );
          }

          final bsmi = home.chartBsmiSeriesK.toList(growable: false);
          final dates = home.chartPointDates.toList(growable: false);
          final marketPrices = home.chartMarketPrices.toList(growable: false);
          final bsmiPrices = home.chartBsmiPrices.toList(growable: false);
          final minY = home.chartMinY.value;
          final maxY = home.chartMaxYk.value;

          final spots = <FlSpot>[
            for (var i = 0; i < series.length; i++)
              FlSpot(i.toDouble(), series[i]),
          ];
          if (spots.length == 1) {
            spots.add(FlSpot(1, spots.first.y));
          }

          final bsmiSpots = <FlSpot>[];
          if (bsmi.length == series.length) {
            for (var i = 0; i < bsmi.length; i++) {
              bsmiSpots.add(FlSpot(i.toDouble(), bsmi[i]));
            }
            if (bsmiSpots.length == 1) {
              bsmiSpots.add(FlSpot(1, bsmiSpots.first.y));
            }
          }

          final maxX = math.max(
            spots.isEmpty ? 1.0 : spots.last.x,
            bsmiSpots.isEmpty ? 0.0 : bsmiSpots.last.x,
          );
          final maxXSafe = math.max(maxX, 1.0);
          final ySpan = maxY - minY;
          final hInterval = ySpan > 0 ? ySpan / 4 : 1.0;
          final vInterval = maxXSafe / 4;

          final chart = LineChart(
            key: ValueKey(
              '${home.selectedChartRange.value.name}_${home.chartRevision.value}',
            ),
            LineChartData(
              minX: 0,
              maxX: maxXSafe,
              minY: minY,
              maxY: maxY,
              backgroundColor: AppColors.chartPlotBackground,
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              clipData: const FlClipData.all(),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: minY,
                    color: AppColors.chartGridLine,
                    strokeWidth: 1,
                    dashArray: const [3, 4],
                  ),
                  HorizontalLine(
                    y: maxY,
                    color: AppColors.chartGridLine,
                    strokeWidth: 1,
                    dashArray: const [3, 4],
                  ),
                ],
              ),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: true,
                horizontalInterval: hInterval > 0 ? hInterval : 1,
                verticalInterval: vInterval > 0 ? vInterval : 1,
                getDrawingHorizontalLine: _homeDottedGridLine,
                getDrawingVerticalLine: _homeDottedGridLine,
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final i = spot.x.round().clamp(0, series.length - 1);
                      final dateLabel = _formatChartDate(
                        i < dates.length ? dates[i] : '',
                      );
                      final String label;
                      final double displayValue;
                      final Color color;
                      if (spot.barIndex == 1 &&
                          bsmiPrices.length == series.length) {
                        label = 'BSMI';
                        displayValue = bsmiPrices[i];
                        color = AppColors.chartLineBsmi;
                      } else {
                        label = 'Market Value';
                        displayValue = i < marketPrices.length
                            ? marketPrices[i]
                            : 0;
                        color = AppColors.chartLineMarketValue;
                      }
                      final priceText = PriceFormatter.format(
                        displayValue.round().toString(),
                      );
                      return LineTooltipItem(
                        '$dateLabel\n$label: $priceText',
                        TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: series.length > 2,
                  curveSmoothness: 0.25,
                  color: AppColors.chartLineMarketValue,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: series.length <= 9,
                    getDotPainter: (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: index == spots.length - 1 ? 3.4 : 2.6,
                        color: AppColors.chartLineMarketValue,
                        strokeWidth: index == spots.length - 1 ? 2 : 1.5,
                        strokeColor: Colors.black.withValues(alpha: 0.25),
                      );
                    },
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
                if (bsmiSpots.isNotEmpty)
                  LineChartBarData(
                    spots: bsmiSpots,
                    isCurved: bsmi.length > 2,
                    curveSmoothness: 0.25,
                    color: AppColors.chartLineBsmi,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: bsmi.length <= 9,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: AppColors.chartLineBsmi,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
              ],
            ),
            duration: AppMotion.chartDraw,
            curve: AppMotion.chart,
          );

          if (!loading) return chart;

          return Stack(
            fit: StackFit.expand,
            children: [
              chart,
              ColoredBox(
                color: AppColors.chartPlotBackground.withValues(alpha: 0.45),
              ),
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold1,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

String _formatChartDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '—';
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return trimmed;
  return DateFormat('MMM d, yyyy').format(parsed);
}
