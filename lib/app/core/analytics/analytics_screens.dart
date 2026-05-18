import '../../routes/app_routes.dart';

/// Human-readable screen keys for Firebase (`{key}_view` events).
abstract final class AnalyticsScreens {
  AnalyticsScreens._();

  /// Shell bottom tabs (when [AppRoutes.shell] is visible).
  static String shellTabScreenName(int index) {
    return switch (index) {
      0 => 'main_home',
      1 => 'main_collection',
      2 => 'main_taste',
      3 => 'main_market',
      4 => 'main_profile',
      _ => 'main_home',
    };
  }

  /// Maps a GetX route name to a stable screen key (no paths / widget names).
  static String screenKeyForRoute(String routeName) {
    switch (routeName) {
      case AppRoutes.splash:
        return 'splash';
      case AppRoutes.shell:
        return 'main_home';
      case AppRoutes.signIn:
        return 'sign_in';
      case AppRoutes.signUp:
        return 'sign_up';
      case AppRoutes.forgotPassword:
        return 'forgot_password';
      case AppRoutes.addToCollection:
        return 'add_to_collection';
      case AppRoutes.tasteBottles:
        return 'taste_bottles';
      case AppRoutes.benchmarkDetail:
        return 'benchmark_detail';
      case AppRoutes.subscription:
        return 'subscription';
      case AppRoutes.settingsAccount:
        return 'settings_account';
      case AppRoutes.settingsNotifications:
        return 'settings_notifications';
      case AppRoutes.settingsPrivacy:
        return 'settings_privacy';
      case AppRoutes.settingsHelp:
        return 'settings_help';
      case AppRoutes.settingsAbout:
        return 'settings_about';
      case AppRoutes.settingsLegalWeb:
        return 'settings_legal_web';
      default:
        return _fallbackKey(routeName);
    }
  }

  static String _fallbackKey(String routeName) {
    if (routeName.isEmpty) return 'unnamed_route';
    var s = routeName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9/]+'), '_');
    s = s.replaceAll('/', '_').replaceAll(RegExp(r'_+'), '_');
    s = s.replaceAll(RegExp(r'^_+|_+$'), '');
    if (s.isEmpty) return 'unnamed_route';
    return s;
  }
}
