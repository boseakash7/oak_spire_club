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

  static TextStyle button20Bold() => GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.black,
      );
}

