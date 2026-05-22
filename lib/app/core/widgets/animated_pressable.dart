import 'package:flutter/material.dart';

import '../animations/app_motion.dart';

/// Subtle scale feedback for tappable cards and rows.
class AnimatedPressable extends StatefulWidget {
  const AnimatedPressable({
    super.key,
    required this.onTap,
    required this.child,
    this.scaleDown = 0.96,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double scaleDown;

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1,
        duration: AppMotion.press,
        curve: AppMotion.pressCurve,
        child: widget.child,
      ),
    );
  }
}

/// Fade + slide in for list sections (optional stagger via [index]).
class FadeSlideEntrance extends StatefulWidget {
  const FadeSlideEntrance({
    super.key,
    required this.child,
    this.index = 0,
  });

  final Widget child;
  final int index;

  @override
  State<FadeSlideEntrance> createState() => _FadeSlideEntranceState();
}

class _FadeSlideEntranceState extends State<FadeSlideEntrance> {
  var _visible = false;

  @override
  void initState() {
    super.initState();
    final delay = AppMotion.staggerStep * widget.index;
    Future<void>.delayed(delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: AppMotion.medium,
      curve: AppMotion.enter,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.07),
        duration: AppMotion.medium,
        curve: AppMotion.enter,
        child: widget.child,
      ),
    );
  }
}
