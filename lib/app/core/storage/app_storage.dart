import 'package:get_storage/get_storage.dart';

class AppStorage {
  AppStorage._();

  static final GetStorage _box = GetStorage();

  static const String _keyUserId = 'user_id';
  static const String _keyUser = 'user';
  static const String _keyUploadUrl = 'upload_url';
  static const String _keyPourPlaceholderUrl = 'pour_image_placeholder';

  static String? get userId => _box.read<String>(_keyUserId);
  static Future<void> setUserId(String value) => _box.write(_keyUserId, value);
  static Future<void> clearUserId() => _box.remove(_keyUserId);

  static Map<String, dynamic>? get user =>
      _box.read<Map<String, dynamic>>(_keyUser);
  static Future<void> setUser(Map<String, dynamic> value) =>
      _box.write(_keyUser, value);
  static Future<void> clearUser() => _box.remove(_keyUser);

  static String? get uploadUrl => _box.read<String>(_keyUploadUrl);
  static Future<void> setUploadUrl(String value) =>
      _box.write(_keyUploadUrl, value);

  static String? get pourImagePlaceholderUrl =>
      _box.read<String>(_keyPourPlaceholderUrl);
  static Future<void> setPourImagePlaceholderUrl(String value) =>
      _box.write(_keyPourPlaceholderUrl, value);
}

