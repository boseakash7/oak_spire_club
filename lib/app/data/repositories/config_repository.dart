import '../../core/storage/app_storage.dart';
import '../datasources/config_remote_datasource.dart';

class ConfigRepository {
  ConfigRepository(this._remote);
  final ConfigRemoteDataSource _remote;

  Future<void> refresh() async {
    final json = await _remote.all();
    final upload = json['upload_url']?.toString().trim();
    if (upload != null && upload.isNotEmpty && upload != 'null') {
      await AppStorage.setUploadUrl(upload);
    }

    final placeholder = json['pour_image_placeholder']?.toString().trim();
    if (placeholder != null && placeholder.isNotEmpty && placeholder != 'null') {
      await AppStorage.setPourImagePlaceholderUrl(placeholder);
    }
  }
}

