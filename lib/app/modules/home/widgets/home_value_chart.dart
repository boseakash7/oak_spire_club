import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../home_controller.dart';

/// Shared plot insets — bottom leaves room for X axis digits inside clip bounds.
const double _kChartPlotLeft = 43;
const double _kChartPlotRight = 12;
const double _kChartPlotTop = 21;
const double _kChartPlotBottom = 30;

class HomeValueChart extends StatelessWidget {
  const HomeValueChart({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    return SizedBox(
      height: 216,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppAssets.homeChart,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _kChartPlotLeft,
                  _kChartPlotTop,
                  _kChartPlotRight,
                  _kChartPlotBottom,
                ),
                child: Obx(
                  () => LineChart(
                    _lineData(
                      seriesK: home.chartSeriesK,
                      maxYk: home.chartMaxYk.value,
                    ),
                    duration: Duration.zero,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Obx(
                () => _AxisLabels(
                  maxYk: home.chartMaxYk.value,
                  maxX: home.chartSeriesK.isEmpty ? 9 : home.chartSeriesK.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _lineData({
    required List<double> seriesK,
    required double maxYk,
  }) {
    // Y is in "k" units to match labels (k = value / 1000).
    final bool hasReal = seriesK.isNotEmpty;
    final List<double> used = hasReal
        ? seriesK
        : const <double>[4.8, 6.5, 5.8, 12.0, 8.2, 8.0, 7.6, 7.9, 12.0];
    final spots = <FlSpot>[
      for (var i = 0; i < used.length; i++) FlSpot(i + 1, used[i]),
    ];

    return LineChartData(
      minX: 1,
      maxX: used.length.toDouble(),
      minY: 0,
      maxY: maxYk,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        verticalInterval: 1,
        horizontalInterval: (maxYk / 15.0) * 2.5,
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.white.withValues(alpha: 0.18),
          strokeWidth: 1,
          dashArray: [3, 6],
        ),
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.white.withValues(alpha: 0.14),
          strokeWidth: 1,
          dashArray: [3, 6],
        ),
      ),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.2,
          color: const Color(0xFFD4AF37),
          barWidth: 2.2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              final isLast = index == spots.length - 1;
              return FlDotCirclePainter(
                radius: isLast ? 3.4 : 2.6,
                color: const Color(0xFFD4AF37),
                strokeWidth: isLast ? 2 : 1.5,
                strokeColor: Colors.black.withValues(alpha: 0.25),
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }
}

class _AxisLabels extends StatelessWidget {
  const _AxisLabels({
    required this.maxYk,
    required this.maxX,
  });

  final double maxYk;
  final int maxX;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.body16().copyWith(
      fontSize: 10,
      color: const Color(0xFFA3A3A3),
      height: 1.0,
      fontFamily: 'Inter',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final leftInset = _kChartPlotLeft;
        final rightInset = _kChartPlotRight;
        final topInset = _kChartPlotTop;
        final bottomInset = _kChartPlotBottom;

        final plotW = w - leftInset - rightInset;
        final plotH = h - topInset - bottomInset;

        Widget yLabel(String text, double yValue /* 0..max */) {
          final t = yValue / maxYk;
          var top = topInset + (1 - t) * plotH - 6;
          // Lift bottom "0" so it does not collide with horizontal "1".
          if (yValue.abs() < 0.001) {
            top -= 11;
          }
          return Positioned(
            left: 6,
            top: top,
            child: SizedBox(
              width: leftInset - 10,
              child: Text(
                text,
                textAlign: TextAlign.right,
                style: style,
              ),
            ),
          );
        }

        const xLabelSlot = 18.0;

        Widget xLabel(String text, int x, int countX) {
          final denom = (countX - 1) == 0 ? 1 : (countX - 1);
          final t = (x - 1) / denom;
          final cx = leftInset + t * plotW;
          final left = (cx - xLabelSlot / 2).clamp(
            4.0,
            w - xLabelSlot - 4,
          );
          return Positioned(
            left: left,
            top: topInset + plotH + 4,
            width: xLabelSlot,
            child: Text(
              text,
              style: style,
              textAlign: TextAlign.center,
            ),
          );
        }

        final nx = maxX < 1 ? 1 : maxX;
        final yTicks = <double>[
          0,
          maxYk * (5 / 15),
          maxYk * (8 / 15),
          maxYk * (10 / 15),
          maxYk * (12 / 15),
          maxYk,
        ];
        String fmtTick(double v) {
          final n = (v).round();
          if (n == 0) return '0';
          return '${n}k';
        }

        return Stack(
          children: [
            for (final t in yTicks) yLabel(fmtTick(t), t),
            for (var i = 1; i <= nx; i++) xLabel('$i', i, nx),
            // Slight gold glow line at bottom of plot border (matches Figma feel)
            Positioned(
              left: leftInset,
              right: rightInset,
              top: topInset + plotH,
              child: Container(
                height: 1,
                color: AppColors.gold1.withValues(alpha: 0.12),
              ),
            ),
          ],
        );
      },
    );
  }
}

