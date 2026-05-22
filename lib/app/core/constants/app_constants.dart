class AppConstants {
  const AppConstants._();

  /// MaterialApp / window title and in-app branding.
  static const String appName = 'Oak Spire Club';

  /// From `bourboneur-app/lib/Core/Constants.dart`
  static const String apiBaseUrl = 'https://www.oakspireclub.com/v2/api/';

  /// Razorpay public key (Key ID). Set your live/test key here.
  ///
  /// Example: `rzp_test_...`
  static const String razorpayKeyId = 'SeBxFTSGiy2WLf';

  static const String termsUrl = 'https://www.oakspireclub.com/terms';
  static const String privacyUrl = 'https://www.oakspireclub.com/privacy-policy';

  static const String supportEmail = 'support@oakspireclub.com';

  /// WhatsApp number with country code, no + or spaces.
  static const String supportWhatsApp = '919876543210';
}
