import '../../core/network/api_client.dart';

class NotificationPrefsRemoteDataSource {
  NotificationPrefsRemoteDataSource(this._client);
  final ApiClient _client;

  static const String _update = 'notification-preferences/update';

  Future<void> updatePreference({
    required String userId,
    required String preferenceKey,
    required bool isEnabled,
  }) async {
    await _client.postJson(_update, {
      'user_id': userId,
      'preference_key': preferenceKey,
      'is_enabled': isEnabled ? 1 : 0,
    });
  }
}
