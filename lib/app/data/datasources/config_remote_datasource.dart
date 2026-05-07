import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class ConfigRemoteDataSource {
  ConfigRemoteDataSource(this._client);
  final ApiClient _client;

  static const String _all = 'config/all';

  Future<Map<String, dynamic>> all() async {
    final response = await _client.get(_all);
    if (response.statusCode != 200) {
      throw ApiException('Internal server error.');
    }

    final json = response.body;
    if (json is! Map) throw ApiException('Unexpected server response.');
    if (json['code']?.toString() != 'OK') {
      throw ApiException(json['data']?.toString() ?? 'Something went wrong.');
    }

    final data = json['data'];
    if (data is! Map) throw ApiException('Unexpected server response.');
    return Map<String, dynamic>.from(data);
  }
}

