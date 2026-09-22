import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The app's standard raised surface: warm vertical gradient, hairline border,
/// rounded corners.
///
/// Home stat / trending cards, collection cards, market rows and detail tiles
/// were each re-declaring the same gradient, border colour and radius by hand.
/// Change the look here, not at the call sites.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.radius = 16,
    this.showBorder = true,
    this.onTap,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final bool showBorder;

  /// When set, the card gets an ink ripple clipped to its corners.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    final surface = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: showBorder ? Border.all(color: AppColors.cardBorder) : null,
        gradient: AppColors.cardSurfaceGradient,
      ),
      child: child,
    );

    if (onTap == null) return surface;

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(onTap: onTap, borderRadius: borderRadius, child: surface),
    );
  }
}
