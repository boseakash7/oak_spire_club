import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color black = Color(0xFF090909);
  static const Color panel = Color(0xFF10090B);
  static const Color border = Color(0xFF414141);
  static const Color white = Colors.white;

  static const Color gold1 = Color(0xFFB9861F);
  static const Color gold2 = Color(0xFFD4AF37);

  /// Brighter gold (trend %, accents).
  static const Color goldBright = Color(0xFFD3AE37);

  /// Rich gold (FAB, collection fill bar).
  static const Color goldRich = Color(0xFFC39628);

  /// Deep charcoal used behind home / collection scroll areas.
  static const Color surfaceDeep = Color(0xFF080405);

  /// Warm cream for primary labels.
  static const Color textCream = Color(0xFFF1E8BE);

  /// Muted warm gray for secondary copy.
  static const Color textMuted = Color(0xFFBAB59F);

  /// Tertiary / caption (e.g. proof line).
  static const Color textWolf = Color(0xFF89746D);

  /// Collection card & chip vertical gradient (top → bottom).
  static const Color cardSurfaceTop = Color(0xFF271C16);
  static const Color cardSurfaceBottom = Color(0xFF201512);

  static const LinearGradient cardSurfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cardSurfaceTop, cardSurfaceBottom],
  );

  /// Soft halo behind bottle art (matches Figma radial stops).
  static const Color bottleGlowGold = Color(0x33D3AE36);
  static const Color bottleGlowEdge = Color(0x00666666);

  static const RadialGradient bottleRadialGlow = RadialGradient(
    center: Alignment.center,
    radius: 0.38,
    colors: [bottleGlowGold, bottleGlowEdge],
    stops: [0.399, 1.0],
  );

  /// Track behind collection “fill” bar.
  static const Color fillBarTrack = Color(0xFF382923);

  /// Fill-level slider thumb (Figma node 108:396).
  static const Color fillSliderThumb = Color(0xFFA27E28);

  /// Bottom navigation bar surface.
  static const Color navBarBackground = Color(0xFF1E1412);

  static const Color navBarBorder = Color(0xFF422F2B);

  // --- Benchmark detail chart (Figma 83:653) ---------------------------------

  /// Plot fill — same token as [surfaceDeep]; kept as alias for readability at call sites.
  static const Color chartPlotBackground = surfaceDeep;

  static const Color chartGridLine = Color(0xFF4A4248);

  /// Upper series (Market Value).
  static const Color chartLineMarketValue = Color(0xFFE8C547);

  /// Lower series (BSMI).
  static const Color chartLineBsmi = Color(0xFFA898C8);

  // --- Detail / tags / rating -------------------------------------------------

  /// Header greeting, near-white on dark.
  static const Color textGreeting = Color(0xFFF5F5F5);

  /// Dark chip surface (AI badge, inactive period tag, etc.).
  static const Color surfaceChip = Color(0xFF1F1E1E);

  /// “Bought at” style caption on owned row.
  static const Color textOwnedLabel = Color(0xFF605F5D);

  static const Color trendPositive = Color(0xFF769828);

  static const Color trendNegative = Color(0xFF982828);

  static const Color tagGoldBorder = Color(0xFF9F8632);

  static const Color tagInactiveBorder = Color(0xFF2D2D2D);

  static const Color ratingChipBackground = Color(0xFF271E21);

  static const Color ratingStarMuted = Color(0xFF7B7878);

  // --- Market list -----------------------------------------------------------

  /// Search field border when focused (lighter than [border]).
  static const Color inputBorderFocused = Color(0xFF585858);

  /// Down / risk accent on benchmark cards.
  static const Color marketTrendDown = Color(0xFFA32A2A);

  /// Light neutral icon tint (e.g. dash placeholder).
  static const Color iconNeutralLight = Color(0xFFD9D9D9);

  /// Sort / filter menu surface (Figma: #221713).
  static const Color menuSurface = Color(0xFF221713);

  /// Selected menu row background (Figma: rgba(241,232,190,0.14)).
  static const Color menuRowSelected = Color(0x24F1E8BE);

  /// Sort chevron inactive tint (Figma: #664C42).
  static const Color sortChevronInactive = Color(0xFF664C42);

  /// Black at ~20% — scrims over dark backgrounds.
  static const Color overlayBlack20 = Color(0x33000000);

  /// Black at ~32% — elevated control shadow.
  static const Color shadowBlack32 = Color(0x52000000);

  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold1, gold2, gold1],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // --- Subscription / IAP (Figma 124:271, 129:320) -------------------------

  /// Skip link, secondary actions — same as [ratingStarMuted].
  static const Color subscriptionSkipLink = ratingStarMuted;

  /// Benefit row gold emphasis.
  static const Color subscriptionBenefitGold = Color(0xFFCA9F2E);

  /// Benefit row alternate gold — same as [goldBright].
  static const Color subscriptionBenefitGoldAlt = goldBright;

  /// “No limits” benefit accents.
  static const Color subscriptionBenefitLimitsPrimary = Color(0xFFC89D2C);
  static const Color subscriptionBenefitLimitsSecondary = Color(0xFFC89C2C);

  /// Plan card border (selected / unselected).
  static const Color subscriptionPlanBorderSelected = Color(0xFFC89D2D);
  static const Color subscriptionPlanBorderUnselected = Color(0xFF060304);

  /// Plan price label (Playfair).
  static const Color subscriptionPriceLabel = Color(0xFFCA9F2E);

  /// Skip confirmation dismiss icon (Figma 129:320).
  static const Color subscriptionSkipDismiss = Color(0xFFC89D2C);

  // --- Delete account --------------------------------------------------------

  /// Destructive actions (delete button, permanent warnings).
  static const Color destructive = Color(0xFFB3261E);

  /// Neutral card surface (Figma delete-account flow).
  static const Color deleteAccountCardBackground = Color(0xFF1C1C1E);

  static const Color deleteAccountCardBorder = Color(0xFF2C2C2E);

  /// Nested inset surface inside delete-account cards.
  static const Color deleteAccountNestedSurface = Color(0xFF141416);

  /// Secondary body copy on delete-account cards.
  static const Color deleteAccountBodyText = Color(0xFF8E8E93);
}

