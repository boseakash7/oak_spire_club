import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  AppTheme._();

  static const SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ColorScheme get colorScheme =>
      ColorScheme.fromSeed(
        seedColor: AppColors.gold1,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.gold2,
        onPrimary: AppColors.black,
        surface: AppColors.schemeSurface,
        surfaceContainerHighest: AppColors.panel,
        onSurface: AppColors.white,
        error: AppColors.errorLight,
      );

  static OutlineInputBorder _inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        borderSide: BorderSide(color: color, width: width),
      );

  /// Primary app theme (dark). Use with [GetMaterialApp.theme].
  ///
  /// Component themes carry the defaults views used to repeat inline; a
  /// widget that sets its own decoration still wins. Page transitions are not
  /// set here: every route uses AppPageTransition (see AppPages).
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.black,
    colorScheme: colorScheme,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: AppTheme.systemUiOverlayStyle,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textGreeting, size: 20),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.panel,
      isDense: true,
      hintStyle: const TextStyle(color: AppColors.textWolf),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      border: _inputBorder(AppColors.border),
      enabledBorder: _inputBorder(AppColors.border),
      focusedBorder: _inputBorder(AppColors.gold2, 1.4),
      errorBorder: _inputBorder(AppColors.errorLight),
      focusedErrorBorder: _inputBorder(AppColors.errorLight, 1.4),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.gold2,
      selectionColor: AppColors.goldGlow,
      selectionHandleColor: AppColors.gold2,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.gold2,
      linearTrackColor: AppColors.fillBarTrack,
      circularTrackColor: Colors.transparent,
      refreshBackgroundColor: AppColors.menuSurface,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.goldRich,
      inactiveTrackColor: AppColors.fillBarTrack,
      thumbColor: AppColors.fillSliderThumb,
      overlayColor: AppColors.goldGlow,
      valueIndicatorColor: AppColors.menuSurface,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.black
            : AppColors.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.gold2
            : AppColors.surfaceChip,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : AppColors.border,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.menuSurface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppColors.borderCocoaSoft,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.sheetTop),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.menuSurface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: AppColors.surfaceCocoa,
      headerForegroundColor: AppColors.textCream,
      todayBorder: const BorderSide(color: AppColors.gold2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.menuSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.gold2),
    ),
  );
}
