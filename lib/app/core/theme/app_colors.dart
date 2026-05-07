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

  /// Bottom navigation bar surface.
  static const Color navBarBackground = Color(0xFF1E1412);

  static const Color navBarBorder = Color(0xFF422F2B);

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
}

