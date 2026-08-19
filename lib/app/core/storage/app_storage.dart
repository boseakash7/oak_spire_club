import 'package:flutter/widgets.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive/hive.dart';

class AppStorage {
  AppStorage._();

  static const String _sessionBoxName = 'oakspire_session_v1';
  static const String _keyUserId = 'user_id';
  static const String _keyUser = 'user';
  static const String _keyUploadUrl = 'upload_url';
  static const String _keyPourPlaceholderUrl = 'pour_image_placeholder';
  static const String _keyRazorpayKeyId = 'razorpay_key_id';
  static const String _keyRazorpayKeySecret = 'razorpay_key_secret';
  static const String _keyCurrentVersion = 'current_version';
  static const String _keyUserGender = 'user_gender';
  static const String _keyNotificationPrefs = 'notification_prefs';
  static const String _keyNotificationTopicsInitialSyncDone =
      'notification_topics_initial_sync_done';
  static const String _keyCurrentRegistrationTopic =
      'current_registration_topic';
  static const String _keyCurrentTierTopic = 'current_tier_topic';
  static const String _keyTrialCountdownEndsAt = 'trial_countdown_ends_at';

  static late final GetStorage _box;
  static late final Box<dynamic> _sessionBox;
  static bool _ready = false;

  /// Must run in [main] before [runApp].
  static Future<void> init() async {
    if (_ready) return;
    WidgetsFlutterBinding.ensureInitialized();
    await GetStorage.init();
    _box = GetStorage();
    _sessionBox = await Hive.openBox<dynamic>(_sessionBoxName);
    await _migrateSessionFromGetStorage();
    _ready = true;
  }

  static Future<void> ensureReady() async {
    if (!_ready) await init();
  }

  static String? _parseId(dynamic value) {
    if (value == null) return null;
    final id = value.toString().trim();
    if (id.isEmpty || id == 'null') return null;
    return id;
  }

  static Map<String, dynamic>? _mapFrom(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  static Map<String, dynamic>? _readMap(String key) {
    final raw = _box.read(key);
    return _mapFrom(raw);
  }

  static String? get userId {
    final fromHive = _parseId(_sessionBox.get(_keyUserId));
    if (fromHive != null) return fromHive;

    final fromKey = _parseId(_box.read(_keyUserId));
    if (fromKey != null) return fromKey;

    return _parseId(_mapFrom(_sessionBox.get(_keyUser))?['id'] ??
        _readMap(_keyUser)?['id']);
  }

  static Map<String, dynamic>? get user {
    final fromHive = _mapFrom(_sessionBox.get(_keyUser));
    if (fromHive != null) return fromHive;
    return _readMap(_keyUser);
  }

  /// Persists login session to Hive (durable on iOS) and GetStorage (legacy).
  static Future<void> saveSession(Map<String, dynamic> userJson) async {
    await ensureReady();
    final id = _parseId(userJson['id']);
    if (id == null) return;

    await _sessionBox.put(_keyUserId, id);
    await _sessionBox.put(_keyUser, userJson);

    await _box.write(_keyUserId, id);
    await _box.write(_keyUser, userJson);
    await _box.save();
  }

  /// Compatibility with older GetStorage-only callers.
  static Future<void> setUserId(String value) async {
    await ensureReady();
    final id = _parseId(value);
    if (id == null) return;
    await _sessionBox.put(_keyUserId, id);
    await _box.write(_keyUserId, id);
    await _box.save();
  }

  /// Compatibility with older GetStorage-only callers.
  static Future<void> setUser(Map<String, dynamic> value) =>
      saveSession(value);

  static Future<void> repairUserIdFromUser() async {
    if (userId != null) return;
    final json = user;
    final id = _parseId(json?['id']);
    if (id == null) return;
    await saveSession(json!);
  }

  static Future<void> clearUserId() async {
    await ensureReady();
    await _sessionBox.delete(_keyUserId);
    await _box.remove(_keyUserId);
    await _box.save();
  }

  static Future<void> clearUser() async {
    await ensureReady();
    await _sessionBox.delete(_keyUser);
    await _box.remove(_keyUser);
    await _box.save();
  }

  /// Clears signed-in user data (logout / delete account).
  static Future<void> clearSession() async {
    await ensureReady();
    await _sessionBox.delete(_keyUserId);
    await _sessionBox.delete(_keyUser);
    await _box.remove(_keyUserId);
    await _box.remove(_keyUser);
    await _box.remove(_keyUserGender);
    await _box.remove(_keyNotificationPrefs);
    await _box.remove(_keyCurrentRegistrationTopic);
    await _box.remove(_keyCurrentTierTopic);
    await _box.save();
  }

  static Future<void> _migrateSessionFromGetStorage() async {
    if (_sessionBox.containsKey(_keyUserId) ||
        _sessionBox.containsKey(_keyUser)) {
      return;
    }

    final id = _parseId(_box.read(_keyUserId));
    final userJson = _readMap(_keyUser);
    if (id == null && userJson == null) return;

    final resolvedId = id ?? _parseId(userJson?['id']);
    if (resolvedId == null || userJson == null) return;

    await _sessionBox.put(_keyUserId, resolvedId);
    await _sessionBox.put(_keyUser, userJson);
  }

  static String? get uploadUrl => _box.read<String>(_keyUploadUrl);
  static Future<void> setUploadUrl(String value) =>
      _box.write(_keyUploadUrl, value);

  static String? get pourImagePlaceholderUrl =>
      _box.read<String>(_keyPourPlaceholderUrl);
  static Future<void> setPourImagePlaceholderUrl(String value) =>
      _box.write(_keyPourPlaceholderUrl, value);

  static String? get razorpayKeyId => _box.read<String>(_keyRazorpayKeyId);
  static Future<void> setRazorpayKeyId(String value) =>
      _box.write(_keyRazorpayKeyId, value);

  static String? get razorpayKeySecret =>
      _box.read<String>(_keyRazorpayKeySecret);
  static Future<void> setRazorpayKeySecret(String value) =>
      _box.write(_keyRazorpayKeySecret, value);

  static Map<String, dynamic>? get currentVersion =>
      _readMap(_keyCurrentVersion);
  static Future<void> setCurrentVersion(Map<String, dynamic> value) =>
      _box.write(_keyCurrentVersion, value);

  static String? get userGender => _box.read<String>(_keyUserGender);
  static Future<void> setUserGender(String? value) async {
    if (value == null || value.isEmpty) {
      await _box.remove(_keyUserGender);
    } else {
      await _box.write(_keyUserGender, value);
    }
  }

  static Map<String, dynamic>? get notificationPrefs =>
      _readMap(_keyNotificationPrefs);
  static Future<void> setNotificationPrefs(Map<String, dynamic> value) =>
      _box.write(_keyNotificationPrefs, value);

  static bool get notificationTopicsInitialSyncDone =>
      _box.read<bool>(_keyNotificationTopicsInitialSyncDone) ?? false;
  static Future<void> setNotificationTopicsInitialSyncDone(bool value) =>
      _box.write(_keyNotificationTopicsInitialSyncDone, value);

  static String? get currentRegistrationTopic =>
      _box.read<String>(_keyCurrentRegistrationTopic);
  static Future<void> setCurrentRegistrationTopic(String? value) async {
    if (value == null) {
      await _box.remove(_keyCurrentRegistrationTopic);
    } else {
      await _box.write(_keyCurrentRegistrationTopic, value);
    }
  }

  static String? get currentTierTopic =>
      _box.read<String>(_keyCurrentTierTopic);
  static Future<void> setCurrentTierTopic(String? value) async {
    if (value == null) {
      await _box.remove(_keyCurrentTierTopic);
    } else {
      await _box.write(_keyCurrentTierTopic, value);
    }
  }

  /// Epoch millis when the 4-hour free-trial countdown ends.
  static int? get trialCountdownEndsAtMillis {
    final value = _box.read(_keyTrialCountdownEndsAt);
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static Future<void> setTrialCountdownEndsAtMillis(int value) =>
      _box.write(_keyTrialCountdownEndsAt, value);
}
