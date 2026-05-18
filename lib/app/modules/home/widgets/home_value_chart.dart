import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/chart_plot_dashed_frame.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../home_controller.dart';

/// Plot insets inside the card. Horizontal margins are tighter so the plot
/// lines up with home body content (scroll uses 23 + section `right: 23`).
/// Left keeps space for compact Y tick labels; bottom for X labels.
const double _kChartPlotLeft = 32;
const double _kChartPlotRight = 6;
const double _kChartPlotTop = 21;
const double _kChartPlotBottom = 30;

FlLine _homeDottedHorizontalGrid(double _) => FlLine(
  color: AppColors.chartGridLine,
  strokeWidth: 0.7,
  dashArray: const [3, 4],
);

/// fl_chart omits vertical grid lines on [minX]/[maxX] and dash styling can be
/// hard to see on dark backgrounds — we paint column guides here (same x mapping
/// as [LineChartData] minX=1, maxX=n on the padded plot rect).
class _HomeChartVerticalGridPainter extends CustomPainter {
  _HomeChartVerticalGridPainter({
    required this.plotInsets,
    required this.columnCount,
  });

  final EdgeInsets plotInsets;
  final int columnCount;

  static const double _dash = 3;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final n = columnCount < 1 ? 1 : columnCount;
    final plotW = size.width - plotInsets.horizontal;
    final plotH = size.height - plotInsets.vertical;
    if (plotW <= 0 || plotH <= 0) return;

    final paint = Paint()
      ..color = AppColors.chartGridLine
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final yTop = plotInsets.top;
    final yBottom = plotInsets.top + plotH;

    for (var k = 1; k <= n; k++) {
      final double x;
      if (n <= 1) {
        x = plotInsets.left + plotW * 0.5;
      } else {
        x = plotInsets.left + (k - 1) / (n - 1) * plotW;
      }
      _drawDashedVertical(canvas, x, yTop, yBottom, paint);
    }
  }

  void _drawDashedVertical(
    Canvas canvas,
    double x,
    double y0,
    double y1,
    Paint paint,
  ) {
    var y = y0;
    while (y < y1 - 0.5) {
      final segEnd = math.min(y + _dash, y1);
      canvas.drawLine(Offset(x, y), Offset(x, segEnd), paint);
      y = segEnd + _gap;
    }
  }

  @override
  bool shouldRepaint(covariant _HomeChartVerticalGridPainter oldDelegate) {
    return oldDelegate.plotInsets != plotInsets ||
        oldDelegate.columnCount != columnCount;
  }
}

class HomeValueChart extends StatelessWidget {
  const HomeValueChart({super.key});

  static const List<double> _fallbackMainK = [
    4.8,
    6.5,
    5.8,
    12.0,
    8.2,
    8.0,
    7.6,
    7.9,
    12.0,
  ];

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 223,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: AppColors.chartPlotBackground),
                ),
                Positioned.fill(
                  child: Obx(() {
                    final home = Get.find<HomeController>();
                    final n = home.chartSeriesK.isEmpty
                        ? 9
                        : home.chartSeriesK.length;
                    return IgnorePointer(
                      child: CustomPaint(
                        painter: _HomeChartVerticalGridPainter(
                          plotInsets: const EdgeInsets.fromLTRB(
                            _kChartPlotLeft,
                            _kChartPlotTop,
                            _kChartPlotRight,
                            _kChartPlotBottom,
                          ),
                          columnCount: n,
                        ),
                      ),
                    );
                  }),
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
                          bsmiK: home.chartBsmiSeriesK,
                          maxYk: home.chartMaxYk.value,
                        ),
                        duration: Duration.zero,
                      ),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: ChartPlotDashedFrameOverlay(
                    plotInsets: EdgeInsets.fromLTRB(
                      _kChartPlotLeft,
                      _kChartPlotTop,
                      _kChartPlotRight,
                      _kChartPlotBottom,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Obx(
                    () => _AxisLabels(
                      maxYk: home.chartMaxYk.value,
                      maxX: home.chartSeriesK.isEmpty
                          ? 9
                          : home.chartSeriesK.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendSwatch(
              color: AppColors.chartLineMarketValue,
              label: 'Market Value',
            ),
            const SizedBox(width: 36),
            _legendSwatch(color: AppColors.chartLineBsmi, label: 'BSMI'),
          ],
        ),
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

  LineChartData _lineData({
    required List<double> seriesK,
    required List<double> bsmiK,
    required double maxYk,
  }) {
    final bool hasReal = seriesK.isNotEmpty;
    final used = hasReal ? seriesK : _fallbackMainK;
    final usedBsmi = hasReal && bsmiK.length == used.length
        ? bsmiK
        : _smoothSeriesK(used);

    final spots = <FlSpot>[
      for (var i = 0; i < used.length; i++) FlSpot(i + 1, used[i]),
    ];
    final bsmiSpots = <FlSpot>[
      for (var i = 0; i < usedBsmi.length; i++) FlSpot(i + 1, usedBsmi[i]),
    ];

    final maxX = used.length.toDouble();
    final hInterval = maxYk > 0 ? maxYk / 4 : 1.0;

    return LineChartData(
      minX: 1,
      maxX: maxX,
      minY: 0,
      maxY: maxYk,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        // Vertical column guides are painted by [_HomeChartVerticalGridPainter]
        // under this chart so they stay visible (fl_chart grid was not showing reliably).
        drawVerticalLine: false,
        drawHorizontalLine: true,
        horizontalInterval: hInterval > 0 ? hInterval : 1,
        getDrawingHorizontalLine: _homeDottedHorizontalGrid,
      ),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: used.length > 2,
          curveSmoothness: 0.25,
          color: AppColors.chartLineMarketValue,
          barWidth: 2,
          dotData: FlDotData(
            show: used.length <= 9,
            getDotPainter: (spot, percent, bar, index) {
              final isLast = index == spots.length - 1;
              return FlDotCirclePainter(
                radius: isLast ? 3.4 : 2.6,
                color: AppColors.chartLineMarketValue,
                strokeWidth: isLast ? 2 : 1.5,
                strokeColor: Colors.black.withValues(alpha: 0.25),
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ),
        LineChartBarData(
          spots: bsmiSpots,
          isCurved: usedBsmi.length > 2,
          curveSmoothness: 0.25,
          color: AppColors.chartLineBsmi,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }
}

List<double> _smoothSeriesK(List<double> k) {
  if (k.isEmpty) return [];
  if (k.length == 1) return [k.first];
  return List<double>.generate(k.length, (i) {
    final i0 = (i - 1).clamp(0, k.length - 1);
    final i2 = (i + 1).clamp(0, k.length - 1);
    return (k[i0] + k[i] + k[i2]) / 3.0;
  });
}

class _AxisLabels extends StatelessWidget {
  const _AxisLabels({required this.maxYk, required this.maxX});

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

        const leftInset = _kChartPlotLeft;
        const rightInset = _kChartPlotRight;
        const topInset = _kChartPlotTop;
        const bottomInset = _kChartPlotBottom;

        final plotW = w - leftInset - rightInset;
        final plotH = h - topInset - bottomInset;

        Widget yLabel(String text, double yValue /* 0..max */) {
          final t = yValue / maxYk;
          var top = topInset + (1 - t) * plotH - 6;
          if (yValue.abs() < 0.001) {
            top -= 11;
          }
          return Positioned(
            left: 6,
            top: top,
            child: SizedBox(
              width: leftInset - 10,
              child: Text(text, textAlign: TextAlign.right, style: style),
            ),
          );
        }

        const xLabelSlot = 18.0;

        Widget xLabel(String text, int x, int countX) {
          final denom = (countX - 1) == 0 ? 1 : (countX - 1);
          final t = (x - 1) / denom;
          final cx = leftInset + t * plotW;
          final left = (cx - xLabelSlot / 2).clamp(4.0, w - xLabelSlot - 4);
          return Positioned(
            left: left,
            top: topInset + plotH + 4,
            width: xLabelSlot,
            child: Text(text, style: style, textAlign: TextAlign.center),
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
