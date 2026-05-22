import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_motion.dart';

/// GPU-friendly dropdown / overlay entrance (opacity + translate + scale only).
Widget appOverlayDropdownEntrance({
  required Animation<double> animation,
  required Widget child,
  Alignment scaleAlignment = Alignment.topLeft,
}) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final t = animation.value.clamp(0.0, 1.0);
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, AppMotion.dropdownSlideY * (1 - t)),
          child: Transform.scale(
            scale: lerpDouble(AppMotion.dropdownScaleFrom, 1, t)!,
            alignment: scaleAlignment,
            child: child,
          ),
        ),
      );
    },
    child: child,
  );
}

/// Light scrim behind overlays — no blur (better on low-end GPUs).
Widget appOverlayScrim({
  required Animation<double> animation,
  required VoidCallback onDismiss,
  double maxOpacity = 0.35,
}) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final t = animation.value.clamp(0.0, 1.0);
      return GestureDetector(
        onTap: onDismiss,
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: maxOpacity * t),
        ),
      );
    },
  );
}
