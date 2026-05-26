import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/user_model.dart';

class UserRemoteDataSource {
  UserRemoteDataSource(this._client);
  final ApiClient _client;

  static const String _getById = 'user/get-by-id';

  Future<UserModel> getById(String id) async {
    final response = await _client.get(_getById, query: {'id': id});
    final json = _client.parseEnvelope(response);

    final data = json['data'];
    if (data is! Map) throw ApiException('Unexpected server response.');
    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }
}

