import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shakes [child] horizontally each time [trigger] changes.
///
/// Used to reject bad input in place — a wrong OTP, for example — so the error
/// is felt where the user is looking instead of only in a toast at the edge of
/// the screen.
class ShakeOnTrigger extends StatefulWidget {
  const ShakeOnTrigger({
    super.key,
    required this.trigger,
    required this.child,
    this.distance = 10,
    this.duration = const Duration(milliseconds: 420),
  });

  /// Any value that changes when a shake should play. A counter is typical.
  final Object? trigger;
  final Widget child;
  final double distance;
  final Duration duration;

  @override
  State<ShakeOnTrigger> createState() => _ShakeOnTriggerState();
}

class _ShakeOnTriggerState extends State<ShakeOnTrigger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didUpdateWidget(ShakeOnTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Three decaying swings, so it reads as a "no" rather than a wobble.
        final t = _controller.value;
        final decay = 1 - t;
        final offset = math.sin(t * math.pi * 6) * widget.distance * decay;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }
}
