import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/user_model.dart';

class UserRemoteDataSource {
  UserRemoteDataSource(this._client);
  final ApiClient _client;

  static const String _getById = 'user/get-by-id';

  Future<UserModel> getById(String id) async {
    final response = await _client.get(_getById, query: {'id': id});
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
    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }
}

