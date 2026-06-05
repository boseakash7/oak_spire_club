import 'package:get_storage/get_storage.dart';

class AppStorage {
  AppStorage._();

  static final GetStorage _box = GetStorage();

  static const String _keyUserId = 'user_id';
  static const String _keyUser = 'user';
  static const String _keyUploadUrl = 'upload_url';
  static const String _keyPourPlaceholderUrl = 'pour_image_placeholder';
  static const String _keyRazorpayKeyId = 'razorpay_key_id';
  static const String _keyRazorpayKeySecret = 'razorpay_key_secret';
  static const String _keyCurrentVersion = 'current_version';
  static const String _keyUserGender = 'user_gender';
  static const String _keyNotificationPrefs = 'notification_prefs';
  static const String _keyNotificationTopicsInitialSyncDone =
      'notification_topics_initial_sync_done';

  static String? get userId => _box.read<String>(_keyUserId);
  static Future<void> setUserId(String value) => _box.write(_keyUserId, value);
  static Future<void> clearUserId() => _box.remove(_keyUserId);

  static Map<String, dynamic>? get user =>
      _box.read<Map<String, dynamic>>(_keyUser);
  static Future<void> setUser(Map<String, dynamic> value) =>
      _box.write(_keyUser, value);
  static Future<void> clearUser() => _box.remove(_keyUser);

  /// Clears signed-in user data (logout / delete account).
  static Future<void> clearSession() async {
    await clearUserId();
    await clearUser();
    await _box.remove(_keyUserGender);
    await _box.remove(_keyNotificationPrefs);
  }

  static String? get uploadUrl => _box.read<String>(_keyUploadUrl);
  static Future<void> setUploadUrl(String value) =>
      _box.write(_keyUploadUrl, value);

  static String? get pourImagePlaceholderUrl =>
      _box.read<String>(_keyPourPlaceholderUrl);
  static Future<void> setPourImagePlaceholderUrl(String value) =>
      _box.write(_keyPourPlaceholderUrl, value);

  static String? get razorpayKeyId => _box.read<String>(_keyRazorpayKeyId);
  static Future<void> setRazorpayKeyId(String value) =>
      _box.write(_keyRazorpayKeyId, value);

  static String? get razorpayKeySecret => _box.read<String>(_keyRazorpayKeySecret);
  static Future<void> setRazorpayKeySecret(String value) =>
      _box.write(_keyRazorpayKeySecret, value);

  static Map<String, dynamic>? get currentVersion =>
      _box.read<Map<String, dynamic>>(_keyCurrentVersion);
  static Future<void> setCurrentVersion(Map<String, dynamic> value) =>
      _box.write(_keyCurrentVersion, value);

  static String? get userGender => _box.read<String>(_keyUserGender);
  static Future<void> setUserGender(String? value) async {
    if (value == null || value.isEmpty) {
      await _box.remove(_keyUserGender);
    } else {
      await _box.write(_keyUserGender, value);
    }
  }

  static Map<String, dynamic>? get notificationPrefs =>
      _box.read<Map<String, dynamic>>(_keyNotificationPrefs);
  static Future<void> setNotificationPrefs(Map<String, dynamic> value) =>
      _box.write(_keyNotificationPrefs, value);

  static bool get notificationTopicsInitialSyncDone =>
      _box.read<bool>(_keyNotificationTopicsInitialSyncDone) ?? false;
  static Future<void> setNotificationTopicsInitialSyncDone(bool value) =>
      _box.write(_keyNotificationTopicsInitialSyncDone, value);
}

