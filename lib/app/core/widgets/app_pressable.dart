import 'package:flutter/material.dart';

import '../animations/app_motion.dart';
import '../utils/app_haptics.dart';

/// How much haptic feedback a press gives.
enum PressHaptic { none, selection, tap }

/// Press feedback for any tappable surface: the child eases down to
/// [scale] while held and springs back on release, with an optional haptic.
///
/// Use it instead of a bare [GestureDetector] on cards, rows, pills and
/// links, so every tappable thing in the app answers the finger the same
/// way. It is exposed to accessibility as a button.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.scale = AppMotion.pressScale,
    this.haptic = PressHaptic.none,
    this.semanticLabel,
  });

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final double scale;
  final PressHaptic haptic;
  final String? semanticLabel;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _handleTap() {
    switch (widget.haptic) {
      case PressHaptic.selection:
        AppHaptics.selection();
      case PressHaptic.tap:
        AppHaptics.tap();
      case PressHaptic.none:
        break;
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: widget.onTap == null ? null : _handleTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _pressed ? widget.scale : 1,
          duration: AppMotion.of(context, AppMotion.press),
          curve: _pressed ? AppMotion.pressCurve : AppMotion.emphasized,
          child: widget.child,
        ),
      ),
    );
  }
}
