import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

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
        surface: const Color.fromARGB(255, 12, 1, 1),
        surfaceContainerHighest: AppColors.panel,
        onSurface: AppColors.white,
      );

  /// Primary app theme (dark). Use with [GetMaterialApp.theme].
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.black,
    colorScheme: colorScheme,
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: AppTheme.systemUiOverlayStyle,
      iconTheme: IconThemeData(color: AppColors.textGreeting, size: 20),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
