import 'package:flutter/widgets.dart';

/// Shared motion tokens for dialogs, charts, routes, and micro-interactions.
/// Favors transform + opacity only so motion stays smooth on low-end devices.
///
/// Every animated widget should read durations through [of] (or check
/// [reduced]) so the system "reduce motion" / "remove animations" setting
/// turns motion off app-wide instead of per screen.
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

  /// Tab body cross-fade in the shell.
  static const Duration tabSwitch = Duration(milliseconds: 260);

  /// One row of a staggered list entrance.
  static const Duration listItem = Duration(milliseconds: 360);

  /// Loading / content / empty swaps.
  static const Duration stateSwitch = Duration(milliseconds: 280);

  /// Count-up numbers (portfolio value, stats).
  static const Duration countUp = Duration(milliseconds: 900);

  /// Slow ambient loops (splash sheen, background drift).
  static const Duration ambient = Duration(milliseconds: 2400);

  /// Rows beyond this slot share the last delay, so a long or paginated list
  /// never makes the user wait for its tail.
  static const int maxStaggerSlots = 8;

  /// Dropdown grows from the filter icon (top-left anchor).
  static const double dropdownScaleFrom = 0.82;
  static const double dropdownSlideY = -16;

  /// Dialogs — slightly stronger so motion reads on small / slow screens.
  static const double dialogScaleFrom = 0.88;
  static const double dialogSlideY = 0.06;

  /// Resting scale of a pressed card / row.
  static const double pressScale = 0.97;

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve dropdownEnter = Curves.easeOutBack;
  static const Curve dropdownExit = Curves.easeInCubic;
  static const Curve chart = Curves.easeOutCubic;
  static const Curve pressCurve = Curves.easeInOut;

  /// Material 3 emphasized easing: fast start, long gentle settle.
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  /// True when the user asked the OS to reduce or remove motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero when motion is reduced.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;

  /// Stagger delay for list slot [index], capped at [maxStaggerSlots].
  static Duration staggerDelay(int index) =>
      staggerStep * index.clamp(0, maxStaggerSlots);
}
