import '../datasources/notification_prefs_remote_datasource.dart';

class NotificationPrefsRepository {
  NotificationPrefsRepository(this._remote);
  final NotificationPrefsRemoteDataSource _remote;

  Future<void> updatePreference({
    required String userId,
    required String preferenceKey,
    required bool isEnabled,
  }) {
    return _remote.updatePreference(
      userId: userId,
      preferenceKey: preferenceKey,
      isEnabled: isEnabled,
    );
  }
}
