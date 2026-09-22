import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// The app's type scale.
///
/// Three families, each with one job:
/// * **Playfair Display** — display / brand headings ([displayXl], [headingL]).
/// * **Roboto** — numbers and body copy (everything in the `body*` / `number*`
///   ramp).
/// * **Inter** — dense UI chrome: nav labels, chips, card titles ([ui*]).
///
/// Prefer a named token over `body16().copyWith(fontSize: …)`. If a size is
/// missing here, add it here rather than at the call site — that is what keeps
/// the app looking like one product.
class AppTextStyles {
  const AppTextStyles._();

  // --- Display / headings (Playfair Display) --------------------------------

  static TextStyle heading32Bold() => GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: AppColors.white,
  );

  /// Brand headings — alias of [heading32Bold] with a scale-consistent name.
  static TextStyle headingL() => heading32Bold();

  static TextStyle headingM() => GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: AppColors.white,
  );

  // --- Numeric / money ------------------------------------------------------

  /// Hero money figure (home collection value). Gradient-masked at call sites.
  static TextStyle displayXl() => GoogleFonts.roboto(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.12,
    color: AppColors.white,
  );

  /// Stat-card values, benchmark average price.
  static TextStyle numberL() => GoogleFonts.roboto(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.textCream,
  );

  static TextStyle numberM() => GoogleFonts.roboto(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.textCream,
  );

  // --- Titles ---------------------------------------------------------------

  /// Section hero label — e.g. home "Collection Value".
  static TextStyle titleL() => GoogleFonts.roboto(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textCream,
  );

  static TextStyle titleM() => GoogleFonts.roboto(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.white,
  );

  static TextStyle titleS() => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.white,
  );

  // --- Body ramp (Roboto) ---------------------------------------------------

  static TextStyle bodyL() => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.white,
  );

  static TextStyle bodyM() => GoogleFonts.roboto(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.white,
  );

  static TextStyle bodyS() => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.white,
  );

  static TextStyle label() => GoogleFonts.roboto(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.textMuted,
  );

  static TextStyle caption() => GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.textMuted,
  );

  static TextStyle captionS() => GoogleFonts.roboto(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.textWolf,
  );

  /// Smallest supported size — proof lines, chart axis ticks.
  static TextStyle micro() => GoogleFonts.roboto(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.textWolf,
  );

  // --- UI chrome (Inter) ----------------------------------------------------
  //
  // These replace `body16().copyWith(fontFamily: 'Inter')`, which asked for a
  // family that is not bundled and silently fell back to the platform font —
  // Roboto on Android, SF Pro on iOS.

  /// Bottom-nav labels.
  static TextStyle uiNavLabel() => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: AppColors.textMuted,
  );

  /// Filter / category chips.
  static TextStyle uiChip() => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.textCream,
  );

  /// Collection card titles and subtitles.
  static TextStyle uiCardTitle() => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.white,
  );

  /// Collection card proof line.
  static TextStyle uiCardMeta() => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.textWolf,
  );

  // --- Legacy ---------------------------------------------------------------

  /// Base body style retained for the many existing
  /// `body16().copyWith(fontSize: …)` call sites. New code should pick a named
  /// token from the ramp above instead.
  static TextStyle body16() => bodyL();

  /// Home — "Moved … in last 3 months" (muted); percent uses gold gradient.
  static TextStyle homeMovedSubtitle() => GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
    color: AppColors.textMovedSubtitle,
  );

  static const LinearGradient collectionValueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.gold2, AppColors.gold1],
    stops: [0.21591, 0.90909],
  );

  static TextStyle button20Bold() => GoogleFonts.roboto(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.black,
  );
}
