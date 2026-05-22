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
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: builder(context),
        ),
      );
    },
  );
}
