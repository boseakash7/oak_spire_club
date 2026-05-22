import 'package:flutter/material.dart';

import '../animations/app_motion.dart';

/// Staggered fade + slide for list / grid rows. Index is capped so long lists
/// stay responsive on low-end devices.
class AnimatedListEntrance extends StatefulWidget {
  const AnimatedListEntrance({
    super.key,
    required this.index,
    required this.child,
    this.enabled = true,
  });

  final int index;
  final Widget child;
  final bool enabled;

  /// Max stagger slot — items beyond this animate together.
  static int staggerIndex(int raw) => raw.clamp(0, 12);

  @override
  State<AnimatedListEntrance> createState() => _AnimatedListEntranceState();
}

class _AnimatedListEntranceState extends State<AnimatedListEntrance> {
  var _visible = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      _visible = true;
      return;
    }
    final delay = AppMotion.staggerStep * AnimatedListEntrance.staggerIndex(
      widget.index,
    );
    Future<void>.delayed(delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void didUpdateWidget(AnimatedListEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _visible = false;
      final delay = AppMotion.staggerStep *
          AnimatedListEntrance.staggerIndex(widget.index);
      Future<void>.delayed(delay, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: AppMotion.medium,
      curve: AppMotion.enter,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        duration: AppMotion.medium,
        curve: AppMotion.enter,
        child: widget.child,
      ),
    );
  }
}
