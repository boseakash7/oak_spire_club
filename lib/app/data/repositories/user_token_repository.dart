import '../datasources/user_token_remote_datasource.dart';

class UserTokenRepository {
  UserTokenRepository(this._remote);
  final UserTokenRemoteDataSource _remote;

  Future<void> saveUserFcm({
    required String userId,
    required String fcmToken,
  }) =>
      _remote.saveUserFcm(userId: userId, fcmToken: fcmToken);

  Future<void> deleteUserFcm({
    required String userId,
    String? fcmToken,
  }) =>
      _remote.deleteUserFcm(userId: userId, fcmToken: fcmToken);
}
