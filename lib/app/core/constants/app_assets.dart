class AppAssets {
  const AppAssets._();

  static const String signInBackground = 'assets/images/signin_bg.png';
  static const String signUpBackground = 'assets/images/signup_bg.png';

  /// Brand mark for splash / about (same asset as launcher source).
  static const String appIc = 'assets/images/app_ic.png';

  static const String homeBottle = 'assets/images/home_bottle.png';
  static const String homeChart = 'assets/images/home_chart.png';

  /// From Figma Collection bottle frame (node 33:132) — fallback when API has no image.
  static const String collectionBottlePlaceholder =
      'assets/images/collection_bottle_placeholder.png';

  /// From Figma Collection trend icon (node 33:70).
  static const String collectionTrendChart = 'assets/icons/collection_trend_chart.svg';

  static const String navHome = 'assets/icons/nav_home.svg';
  static const String navCollection = 'assets/icons/nav_collection.svg';

  static const String iconArrowRight = 'assets/icons/arrow_right.svg';
}
