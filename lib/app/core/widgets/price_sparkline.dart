import 'package:flutter/material.dart';

import '../../data/models/price_sparkline.dart';
import '../animations/app_motion.dart';
import '../theme/app_colors.dart';

/// A bottle's recent price as a tiny step line for list rows: green when it
/// rose over the window, red when it fell, muted when flat.
///
/// Drawn with a [CustomPainter] rather than fl_chart, which is far heavier
/// per row and whose touch handling a row does not need. Prices hold until
/// the next change (history is change-only), so the line steps, the same as
/// the bottle detail chart. While [data] is null a dashed baseline holds the
/// space so the row does not shift when it arrives.
class PriceSparklineView extends StatelessWidget {
  const PriceSparklineView({
    super.key,
    required this.data,
    this.width = 64,
    this.height = 24,
  });

  final PriceSparkline? data;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final d = data;
    final ready = d != null && !d.isEmpty;
    final color = !ready
        ? AppColors.tagInactiveBorder
        : d.isUp
        ? AppColors.trendPositive
        : d.isDown
        ? AppColors.marketTrendDown
        : AppColors.textWolf;

    return SizedBox(
      width: width,
      height: height,
      child: AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.fast),
        child: RepaintBoundary(
          key: ValueKey(ready),
          child: CustomPaint(
            size: Size(width, height),
            painter: ready
                ? _StepLinePainter(prices: d.prices, color: color)
                : const _BaselinePainter(color: AppColors.tagInactiveBorder),
          ),
        ),
      ),
    );
  }
}

class _StepLinePainter extends CustomPainter {
  _StepLinePainter({required this.prices, required this.color});

  final List<double> prices;
  final Color color;

  static const double _stroke = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    var lo = prices.first;
    var hi = prices.first;
    for (final p in prices) {
      if (p < lo) lo = p;
      if (p > hi) hi = p;
    }
    final span = hi - lo;
    const pad = _stroke;
    final h = size.height - pad * 2;
    // A flat window sits in the middle rather than on the floor.
    double y(double p) => span == 0 ? size.height / 2 : pad + h * (1 - (p - lo) / span);
    final step = size.width / (prices.length - 1);

    final line = Path()..moveTo(0, y(prices.first));
    for (var i = 1; i < prices.length; i++) {
      final x = step * i;
      line
        ..lineTo(x, y(prices[i - 1]))
        ..lineTo(x, y(prices[i]));
    }

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StepLinePainter old) =>
      old.color != color || !_samePrices(old.prices, prices);

  static bool _samePrices(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _BaselinePainter extends CustomPainter {
  const _BaselinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final y = size.height / 2;
    const dash = 3.0;
    for (var x = 0.0; x < size.width; x += dash * 2) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
    }
  }

  @override
  bool shouldRepaint(_BaselinePainter old) => old.color != color;
}
