class AppConstants {
  const AppConstants._();

  /// MaterialApp / window title and in-app branding.
  static const String appName = 'Oak Spire Club';

  /// Production by default. Point a debug build at a local backend with
  /// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2/v2/api/`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://www.oakspireclub.com/v2/api/',
  );

  /// Razorpay keys come from `config/all` → `razorpay_key_id` / `razorpay_key_secret`.
  /// See [AppStorage.razorpayKeyId] after [AppConfigController.refresh].

  static const String termsUrl = 'https://www.oakspireclub.com/terms';
  static const String privacyUrl =
      'https://www.oakspireclub.com/privacy-policy';

  static const String supportEmail = 'support@oakspireclub.com';

  /// WhatsApp number with country code, no + or spaces.
  static const String supportWhatsApp = '919876543210';

  /// Numeric App Store ID for iOS store redirect (set when published).
  static const String iosAppStoreId = '';

  /// Fallback App Store product IDs when `apple_store_id` is missing from API.
  static const String appleMonthlyProductId = 'monthly_sub';
  static const String appleYearlyProductId = 'yearly_plan';

  /// Manage / cancel Apple subscriptions (Settings → Apple ID → Subscriptions).
  static const String appleSubscriptionsUrl =
      'https://apps.apple.com/account/subscriptions';
}
