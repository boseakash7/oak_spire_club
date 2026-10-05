import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Spacing scale. Screens were built from Figma with one-off paddings; new
/// and refactored code picks from this scale instead.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal page gutter used by the shell tabs.
  static const double gutter = 20;
}

/// Button metrics, so a primary action is the same size on every screen.
/// [compact] is the inline size (the empty state's "Browse bottles").
abstract final class AppButtonSize {
  static const double regular = 44;
  static const double compact = 40;
  static const double radius = 10;
  static const double labelSize = 16;
}

/// Corner radii.
abstract final class AppRadii {
  static const double chip = 999;
  static const double sm = 9;
  static const double md = 12;
  static const double card = 16;
  static const double sheet = 24;

  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// Elevation, expressed as warm glows rather than grey drop shadows so
/// surfaces lift without muddying the dark palette.
abstract final class AppShadows {
  /// Resting card.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.shadowBlack32,
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  /// Pressed / selected gold emphasis.
  static const List<BoxShadow> goldGlow = [
    BoxShadow(color: AppColors.goldGlow, blurRadius: 18, spreadRadius: -2),
  ];

  /// Floating action button.
  static const List<BoxShadow> fab = [
    BoxShadow(color: AppColors.goldGlow, blurRadius: 22, offset: Offset(0, 6)),
    BoxShadow(
      color: AppColors.shadowBlack32,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
