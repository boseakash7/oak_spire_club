import 'package:flutter/material.dart';

/// Shared motion tokens for dialogs, charts, routes, and micro-interactions.
/// Favors transform + opacity only so motion stays smooth on low-end devices.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration dialog = Duration(milliseconds: 340);
  static const Duration sheet = Duration(milliseconds: 380);
  static const Duration dropdown = Duration(milliseconds: 280);
  static const Duration page = Duration(milliseconds: 340);
  static const Duration chartDraw = Duration(milliseconds: 750);
  static const Duration chartReflow = Duration(milliseconds: 500);
  static const Duration press = Duration(milliseconds: 140);
  static const Duration staggerStep = Duration(milliseconds: 45);
  static const Duration chip = Duration(milliseconds: 220);

  /// Dropdown grows from the filter icon (top-left anchor).
  static const double dropdownScaleFrom = 0.82;
  static const double dropdownSlideY = -16;

  /// Dialogs — slightly stronger so motion reads on small / slow screens.
  static const double dialogScaleFrom = 0.88;
  static const double dialogSlideY = 0.06;

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve dropdownEnter = Curves.easeOutBack;
  static const Curve dropdownExit = Curves.easeInCubic;
  static const Curve chart = Curves.easeOutCubic;
  static const Curve pressCurve = Curves.easeInOut;
}
