import 'package:flutter/material.dart';

import '../animations/app_dialog_transitions.dart';
import '../animations/app_motion.dart';

/// Animated general dialog (scale + fade).
Future<T?> showAppAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color? barrierColor,
  Duration? transitionDuration,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ?? 'Dismiss',
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.72),
    transitionDuration: transitionDuration ?? AppMotion.dialog,
    transitionBuilder: appDialogScaleFadeTransition,
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
  );
}

/// Animated bottom sheet (slide up + fade).
Future<T?> showAppAnimatedBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool isScrollControlled = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: AppMotion.sheet,
    transitionBuilder: appSheetSlideTransition,
    pageBuilder: (context, animation, secondaryAnimation) {
      final sheet = Material(
        color: Colors.transparent,
        child: builder(context),
      );
      return Align(
        alignment: Alignment.bottomCenter,
        // A sheet that can be dismissed by tapping outside can also be
        // flung / dragged down, like a native sheet.
        child: barrierDismissible ? _DragToDismiss(child: sheet) : sheet,
      );
    },
  );
}

/// Follows a downward drag and pops the route past a distance or fling
/// velocity; otherwise springs back.
class _DragToDismiss extends StatefulWidget {
  const _DragToDismiss({required this.child});

  final Widget child;

  @override
  State<_DragToDismiss> createState() => _DragToDismissState();
}

class _DragToDismissState extends State<_DragToDismiss>
    with SingleTickerProviderStateMixin {
  static const double _dismissDistance = 110;
  static const double _dismissVelocity = 700;

  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  )..addListener(() => setState(() => _dy = _backFrom * (1 - _back.value)));

  double _dy = 0;
  double _backFrom = 0;
  bool _popped = false;

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails d) {
    _back.stop();
    setState(() => _dy = (_dy + d.delta.dy).clamp(0.0, double.infinity));
  }

  void _onEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (!_popped && (_dy > _dismissDistance || v > _dismissVelocity)) {
      _popped = true;
      Navigator.of(context).maybePop();
      return;
    }
    _backFrom = _dy;
    _back.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _onUpdate,
      onVerticalDragEnd: _onEnd,
      child: Transform.translate(offset: Offset(0, _dy), child: widget.child),
    );
  }
}
