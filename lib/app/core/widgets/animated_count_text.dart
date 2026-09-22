import 'package:flutter/material.dart';

import '../animations/app_motion.dart';

/// Counts from the previously shown value up to [value] instead of snapping.
///
/// Used for money and tallies that land after a fetch. [format] turns the
/// in-flight double into display text, so the caller keeps control of currency
/// and rounding.
class AnimatedCountText extends StatelessWidget {
  const AnimatedCountText({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = AppMotion.chartDraw,
    this.textAlign,
  });

  final double value;
  final String Function(double) format;
  final TextStyle? style;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: AppMotion.standard,
      builder: (context, animated, _) {
        return Text(format(animated), style: style, textAlign: textAlign);
      },
    );
  }
}

/// Integer variant for counters such as "Total Collection".
class AnimatedCountInt extends StatelessWidget {
  const AnimatedCountInt({
    super.key,
    required this.value,
    this.style,
    this.duration = AppMotion.chartReflow,
  });

  final int value;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedCountText(
      value: value.toDouble(),
      duration: duration,
      style: style,
      format: (v) => v.round().toString(),
    );
  }
}
