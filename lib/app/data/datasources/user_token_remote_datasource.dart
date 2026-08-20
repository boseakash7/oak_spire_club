import '../../core/network/api_client.dart';

class UserTokenRemoteDataSource {
  UserTokenRemoteDataSource(this._client);
  final ApiClient _client;

  static const String _saveUserFcm = 'usertoken/save-user-fcm';
  static const String _deleteUserFcm = 'usertoken/delete-user-fcm';

  Future<void> saveUserFcm({
    required String userId,
    required String fcmToken,
  }) async {
    await _client.postJson(_saveUserFcm, {
      'user_id': userId,
      'fcm_token': fcmToken,
    });
  }

  Future<void> deleteUserFcm({
    required String userId,
    String? fcmToken,
  }) async {
    final body = <String, dynamic>{'user_id': userId};
    final token = fcmToken?.trim();
    if (token != null && token.isNotEmpty) {
      body['fcm_token'] = token;
    }
    await _client.postJson(_deleteUserFcm, body);
  }
}
