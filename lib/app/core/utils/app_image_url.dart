import '../constants/app_constants.dart';
import '../storage/app_storage.dart';

/// Turns a bottle `image` field into a loadable URL.
///
/// The API returns either a full URL (bot-downloaded art, CDN) or a bare
/// file name in `Application/Uploads`, which resolves against `upload_url`
/// from `config/all`, or failing that, against the API's own host.
abstract final class AppImageUrl {
  static String? resolve(String? raw0) {
    var raw = raw0?.trim();
    if (raw == null || raw.isEmpty || raw == 'null') return null;

    if (raw.startsWith('//')) raw = 'https:$raw';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    final uploadUrl = AppStorage.uploadUrl?.trim();
    if (uploadUrl != null && uploadUrl.isNotEmpty) {
      return '${uploadUrl.replaceAll(RegExp(r'/+$'), '')}/$raw';
    }

    final api = Uri.parse(AppConstants.apiBaseUrl);
    return Uri(
      scheme: api.scheme,
      host: api.host,
      port: api.hasPort ? api.port : null,
      path: raw.startsWith('/') ? raw : '/$raw',
    ).toString();
  }
}
