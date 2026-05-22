import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Fade + scale + slide dialog entrance (settings, confirms).
Widget appDialogScaleFadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: AppMotion.dropdownEnter,
    reverseCurve: AppMotion.exit,
  );
  return AnimatedBuilder(
    animation: curved,
    builder: (context, child) {
      final t = curved.value.clamp(0.0, 1.0);
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, AppMotion.dialogSlideY * 40 * (1 - t)),
          child: Transform.scale(
            scale: lerpDouble(AppMotion.dialogScaleFrom, 1, t)!,
            alignment: Alignment.center,
            child: child,
          ),
        ),
      );
    },
    child: child,
  );
}

/// Slide up from bottom (bottom sheets).
Widget appSheetSlideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: AppMotion.enter,
    reverseCurve: AppMotion.exit,
  );
  return AnimatedBuilder(
    animation: curved,
    builder: (context, child) {
      final t = curved.value.clamp(0.0, 1.0);
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 48 * (1 - t)),
          child: child,
        ),
      );
    },
    child: child,
  );
}

/// Subtle fade + upward slide for full-screen routes.
Widget appPageFadeSlideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: AppMotion.enter,
    reverseCurve: AppMotion.exit,
  );
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}

/// Backdrop that fades with the route animation.
Color appDialogBarrierColor(double animationValue) {
  return Colors.black.withValues(alpha: 0.72 * animationValue.clamp(0.0, 1.0));
}
