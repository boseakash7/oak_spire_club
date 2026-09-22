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
  static const Color subscriptionPlanBorderUnselected = Color(0xFF422E27);

  /// “Billed every …” on plan cards.
  static const Color subscriptionBillingSubtitle = Color(0xFF787878);

  /// Trial countdown digits.
  static const Color subscriptionTrialTime = Color(0xFFD0A934);

  /// Trial progress track.
  static const Color subscriptionTrialTrack = Color(0xFF201116);

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

  // --- Card surfaces ---------------------------------------------------------

  /// Hairline border around elevated cards (home stat / trending, detail tiles).
  static const Color cardBorder = Color(0xFF4A342E);

  /// Muted label inside stat cards ("Total Collection").
  static const Color textStatLabel = Color(0xFF997C71);

  /// Secondary line on home trending cards.
  static const Color textTrendingSubtitle = Color(0xFF87665A);

  /// "Moved … in last 3 months" caption.
  static const Color textMovedSubtitle = Color(0xFF9D9C9C);

  // --- Skeleton / shimmer ----------------------------------------------------

  static const Color shimmerBase = Color(0xFF2A1E1A);
  static const Color shimmerHighlight = Color(0xFF3A2A24);

  // --- Onboarding / OTP accents ---------------------------------------------

  /// Primary gold used across get-started and OTP artwork.
  static const Color goldAccent = Color(0xFFCCA230);

  /// Same gold at ~10% — soft glows behind artwork.
  static const Color goldAccentGlow = Color(0x1ACCA230);

  static const Color goldSoft = Color(0xFFD4A76A);
  static const Color goldDeep = Color(0xFF9B6D3B);
  static const Color goldMid = Color(0xFFC59358);
  static const Color goldPale = Color(0xFFE8D9A0);
  static const Color goldEmber = Color(0xFF1A1208);

  // --- Feedback --------------------------------------------------------------

  /// Error text / error snackbar accent.
  static const Color errorLight = Color(0xFFE57373);

  /// Success snackbar accent.
  static const Color successLight = Color(0xFFC8E6C9);

  /// Deep red wash behind destructive confirmations.
  static const Color destructiveDeep = Color(0xFF8B2929);

  static const Color destructiveSurface = Color(0xFF3A1A1A);

  /// WhatsApp brand green (help & support contact row).
  static const Color whatsappGreen = Color(0xFF25D366);

  // --- Neutral surfaces ------------------------------------------------------

  static const Color surfaceInk = Color(0xFF161010);
  static const Color surfaceInkSoft = Color(0xFF1A100F);
  static const Color surfaceInkDeep = Color(0xFF18100E);
  static const Color surfaceCocoa = Color(0xFF2E211C);
  static const Color surfaceCocoaDeep = Color(0xFF2A1C16);
  static const Color borderCocoa = Color(0xFF5C453C);
  static const Color borderCocoaSoft = Color(0xFF6B5348);
  static const Color borderNeutral = Color(0xFF3C3B3B);

  /// Near-opaque ink used for dialog / sheet scrims.
  static const Color scrimInk = Color(0xE8171210);

  // --- Neutral text ----------------------------------------------------------

  static const Color textNeutralBright = Color(0xFFE6E6E6);
  static const Color textNeutralWarm = Color(0xFFE8E2D6);
  static const Color textNeutralSoft = Color(0xFFD8D2C6);
  static const Color textNeutralMuted = Color(0xFFC8C2B6);

  // --- Charts ----------------------------------------------------------------

  /// Area fill under the market-value line (top → transparent).
  static const LinearGradient chartMarketValueArea = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x40E8C547), Color(0x00E8C547)],
  );

  /// Area fill under the BSMI line.
  static const LinearGradient chartBsmiArea = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x26A898C8), Color(0x00A898C8)],
  );

  /// Vertical crosshair drawn while scrubbing a chart.
  static const Color chartCrosshair = Color(0x66F1E8BE);

  /// Tooltip surface behind chart readouts.
  static const Color chartTooltipSurface = Color(0xF21F1512);
}
