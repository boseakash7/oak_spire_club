import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);
  final ApiClient _client;

  static const String _register = 'auth/register';
  static const String _login = 'auth/login';

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.postJson(_login, {
      'email': email.trim(),
      'password': password,
    });

    final data = json['data'];
    if (data is! Map) {
      throw ApiException('Unexpected server response.');
    }
    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    bool subscribe = false,
  }) async {
    final json = await _client.postJson(_register, {
      'full_name': fullName,
      'email': email.trim(),
      'password': password,
      'subscribe': subscribe ? 1 : 0,
    });

    final data = json['data'];
    if (data is! Map) {
      throw ApiException('Unexpected server response.');
    }
    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }
}

