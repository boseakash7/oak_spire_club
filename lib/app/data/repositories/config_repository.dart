import '../../core/storage/app_storage.dart';
import '../datasources/config_remote_datasource.dart';
import '../models/app_current_version_model.dart';

class ConfigRepository {
  ConfigRepository(this._remote);
  final ConfigRemoteDataSource _remote;

  Future<void> refresh() async {
    final json = await _remote.all();
    await _saveIfPresent(json['upload_url'], AppStorage.setUploadUrl);
    await _saveIfPresent(
      json['pour_image_placeholder'],
      AppStorage.setPourImagePlaceholderUrl,
    );
    await _saveIfPresent(json['razorpay_key_id'], AppStorage.setRazorpayKeyId);
    await _saveIfPresent(
      json['razorpay_key_secret'],
      AppStorage.setRazorpayKeySecret,
    );
    await _saveCurrentVersion(json['current_version']);
  }

  static Future<void> _saveCurrentVersion(dynamic raw) async {
    if (raw is! Map) return;
    final version = AppCurrentVersion.fromJson(Map<String, dynamic>.from(raw));
    if (version.android == null && version.ios == null) return;
    await AppStorage.setCurrentVersion(version.toJson());
  }

  static Future<void> _saveIfPresent(
    dynamic raw,
    Future<void> Function(String value) save,
  ) async {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty || value == 'null') return;
    await save(value);
  }
}

