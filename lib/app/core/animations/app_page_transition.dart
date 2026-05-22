import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_dialog_transitions.dart';

/// GetX route transition: fade + slight upward slide.
class AppFadeSlideTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return appPageFadeSlideTransition(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }

}
