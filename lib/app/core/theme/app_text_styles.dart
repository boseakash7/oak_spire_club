import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle heading32Bold() => GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: AppColors.white,
      );

  static TextStyle body16() => GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.2,
        color: AppColors.white,
      );

  /// Home — “Moved … in last 3 months” (muted); percent uses gold gradient in UI.
  static TextStyle homeMovedSubtitle() => GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.0,
        letterSpacing: 0,
        color: const Color(0xFF9D9C9C),
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

