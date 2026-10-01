import 'package:flutter/material.dart';

import '../animations/app_motion.dart';
import '../theme/app_colors.dart';

/// A horizontal level bar (bottle fill) that grows to [value] when first
/// shown and eases to any new value.
class AnimatedFillBar extends StatelessWidget {
  const AnimatedFillBar({
    super.key,
    required this.value,
    this.height = 4,
    this.trackColor = AppColors.fillBarTrack,
    this.fillColor = AppColors.goldRich,
    this.radius = 999,
  });

  /// 0..1; values outside are clamped.
  final double value;
  final double height;
  final Color trackColor;
  final Color fillColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final target = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: trackColor,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: target),
            duration: AppMotion.of(context, AppMotion.countUp),
            curve: AppMotion.emphasizedDecelerate,
            builder: (context, v, _) => FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              child: ColoredBox(color: fillColor),
            ),
          ),
        ),
      ),
    );
  }
}
