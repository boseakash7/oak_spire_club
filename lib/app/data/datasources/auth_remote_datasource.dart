import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);
  final ApiClient _client;

  static const String _register = 'auth/register';
  static const String _login = 'auth/login';
  static const String _update = 'auth/update';
  static const String _delete = 'auth/delete';
  static const String _sendOtp = 'auth/send-otp';
  static const String _verifyOtp = 'auth/verify-otp';

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

  Future<void> updateProfile({
    required String userId,
    required String name,
    String? gender,
    String? oldPassword,
    String? password,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'name': name,
    };
    if (gender != null && gender.isNotEmpty) {
      body['gender'] = gender;
    }
    if (oldPassword != null && oldPassword.isNotEmpty) {
      body['old_password'] = oldPassword;
    }
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    await _client.postJson(_update, body);
  }

  Future<void> sendOtp({required String email}) async {
    await _client.postJson(_sendOtp, {'email': email.trim()});
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    await _client.postJson(_verifyOtp, {
      'email': email.trim(),
      'otp': otp,
    });
  }

  Future<void> deleteAccount({required String userId}) async {
    await _client.postJson(_delete, {'id': userId});
  }
}

