import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../animations/app_motion.dart';
import '../theme/app_colors.dart';

/// One shimmer sweep across a whole skeleton.
///
/// Wrap a loading view's root in it: every [ShimmerBox] inside then paints a
/// plain placeholder and this single shimmer sweeps across all of them in
/// step, instead of each box running its own out-of-sync animation.
class ShimmerScope extends StatelessWidget {
  const ShimmerScope({
    super.key,
    required this.child,
    this.baseColor = AppColors.shimmerBase,
    this.highlightColor = AppColors.shimmerHighlight,
  });

  final Widget child;

  /// Override both for placeholders on a card surface, e.g.
  /// [AppColors.shimmerOnCardBase] / [AppColors.shimmerOnCardHighlight].
  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return _ShimmerScopeMarker(
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: const Duration(milliseconds: 1400),
        enabled: !AppMotion.reduced(context),
        child: child,
      ),
    );
  }
}

class _ShimmerScopeMarker extends InheritedWidget {
  const _ShimmerScopeMarker({required super.child});

  @override
  bool updateShouldNotify(_ShimmerScopeMarker oldWidget) => false;
}

/// A placeholder block in a loading skeleton. Inside a [ShimmerScope] it is
/// a plain block; on its own it shimmers by itself.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.height,
    required this.width,
    this.radius = 12,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    if (context.getInheritedWidgetOfExactType<_ShimmerScopeMarker>() != null) {
      return box;
    }

    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      enabled: !AppMotion.reduced(context),
      child: box,
    );
  }
}

/// A skeleton on real surfaces. [builder] lays the skeleton out twice: with
/// `placeholders: false` it draws the surfaces (cards, fields), and with
/// `placeholders: true` the [ShimmerBox]es that sit on them, inside one
/// [ShimmerScope] in the on-card colours. So a single sweep runs over the
/// details while the cards keep the colour of the real rows. Wrap anything
/// that only one layer draws in a [ShimmerSlot].
class ShimmerCardLayers extends StatelessWidget {
  const ShimmerCardLayers({super.key, required this.builder});

  final Widget Function(bool placeholders) builder;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        builder(false),
        Positioned.fill(
          child: ShimmerScope(
            baseColor: AppColors.shimmerOnCardBase,
            highlightColor: AppColors.shimmerOnCardHighlight,
            child: builder(true),
          ),
        ),
      ],
    );
  }
}

/// Inside a [ShimmerCardLayers] builder: shows [child] in the placeholder
/// layer and keeps it as empty space of the same size in the surface layer.
class ShimmerSlot extends StatelessWidget {
  const ShimmerSlot({
    super.key,
    required this.placeholders,
    required this.child,
  });

  final bool placeholders;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (placeholders) return child;
    return Visibility(
      visible: false,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: child,
    );
  }
}

/// A placeholder text line [widthFactor] of the available width.
class ShimmerLine extends StatelessWidget {
  const ShimmerLine({
    super.key,
    required this.widthFactor,
    required this.height,
  });

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: ShimmerBox(height: height, width: double.infinity, radius: 4),
    );
  }
}
