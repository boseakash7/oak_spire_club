import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Platform conventions in one place, so views ask "which feel?" rather than
/// checking `Platform.isIOS` (which also breaks widget tests).
///
/// Only look and feel lives here. Payment gateways and other behaviour that
/// differs by store keep their own checks.
abstract final class AppPlatform {
  /// iOS / macOS conventions: Cupertino transitions, bounce, pickers.
  static bool get isCupertino =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  /// Scroll physics that feel native: bounce on iOS, clamp (with the Material
  /// stretch overscroll) on Android. Always scrollable, so pull-to-refresh
  /// works on short content.
  static ScrollPhysics get scrollPhysics => isCupertino
      ? const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics())
      : const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics());

  /// Leading back icon: chevron on iOS, arrow on Android.
  static IconData get backIcon =>
      isCupertino ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_rounded;
}
