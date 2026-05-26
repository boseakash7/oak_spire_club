import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class ConfigRemoteDataSource {
  ConfigRemoteDataSource(this._client);
  final ApiClient _client;

  static const String _all = 'config/all';

  Future<Map<String, dynamic>> all() async {
    final response = await _client.get(_all);
    final json = _client.parseEnvelope(response);

    final data = json['data'];
    if (data is! Map) throw ApiException('Unexpected server response.');
    return Map<String, dynamic>.from(data);
  }
}

