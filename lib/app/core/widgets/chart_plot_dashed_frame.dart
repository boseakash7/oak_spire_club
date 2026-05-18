import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Dotted/dashed rectangle on all four sides (Figma-style closed plot frame).
class ChartPlotDashedFramePainter extends CustomPainter {
  ChartPlotDashedFramePainter({
    required this.plotInsets,
    this.color = AppColors.chartGridLine,
    this.strokeWidth = 0.7,
    this.dashLength = 3,
    this.gapLength = 4,
  });

  final EdgeInsets plotInsets;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  void _dashedSegment(Canvas canvas, Offset a, Offset b, Paint paint) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1e-6) return;
    final ux = dx / len;
    final uy = dy / len;
    var t = 0.0;
    while (t < len) {
      final t1 = math.min(t + dashLength, len);
      canvas.drawLine(
        Offset(a.dx + ux * t, a.dy + uy * t),
        Offset(a.dx + ux * t1, a.dy + uy * t1),
        paint,
      );
      t += dashLength + gapLength;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      plotInsets.left,
      plotInsets.top,
      math.max(0.0, size.width - plotInsets.horizontal),
      math.max(0.0, size.height - plotInsets.vertical),
    );
    if (rect.width <= 0 || rect.height <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    _dashedSegment(canvas, rect.topLeft, rect.topRight, paint);
    _dashedSegment(canvas, rect.topRight, rect.bottomRight, paint);
    _dashedSegment(canvas, rect.bottomRight, rect.bottomLeft, paint);
    _dashedSegment(canvas, rect.bottomLeft, rect.topLeft, paint);
  }

  @override
  bool shouldRepaint(covariant ChartPlotDashedFramePainter oldDelegate) {
    return oldDelegate.plotInsets != plotInsets ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}

/// Non-interactive overlay; place in a [Stack] above the [LineChart].
class ChartPlotDashedFrameOverlay extends StatelessWidget {
  const ChartPlotDashedFrameOverlay({
    super.key,
    required this.plotInsets,
    this.color = AppColors.chartGridLine,
    this.strokeWidth = 0.7,
    this.dashLength = 3,
    this.gapLength = 4,
  });

  final EdgeInsets plotInsets;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: ChartPlotDashedFramePainter(
          plotInsets: plotInsets,
          color: color,
          strokeWidth: strokeWidth,
          dashLength: dashLength,
          gapLength: gapLength,
        ),
      ),
    );
  }
}
