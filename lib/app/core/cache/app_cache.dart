import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A small, versioned, TTL-based cache for API payloads.
///
/// Rules:
/// - **TTL**: entries expire after [ttl]
/// - **Version**: entries are invalidated when app version changes
/// - **Force refresh**: callers can bypass cache (pull-to-refresh)
///
/// Storage format: `Map` values in Hive box:
/// `{ v: appVersion, t: epochMs, d: jsonString }`
class AppCache {
  AppCache._(this._box, this._appVersion);

  static const String boxName = 'app_cache_v1';

  final Box<Map> _box;
  final String _appVersion;

  static Future<AppCache> init() async {
    final box = await Hive.openBox<Map>(boxName);
    final info = await PackageInfo.fromPlatform();
    return AppCache._(box, info.version);
  }

  /// Fetch with cache.
  ///
  /// [cacheKey] should include user context when needed (e.g. `collection:$userId`).
  Future<T> getOrFetch<T>({
    required String cacheKey,
    required Duration ttl,
    required Future<T> Function() fetch,
    required Object Function(T value) encode,
    required T Function(Object json) decode,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _read(cacheKey);
      if (cached != null && !cached.isExpired(ttl)) return cached(decode);
    }

    final value = await fetch();
    await _write(cacheKey, encode(value));
    return value;
  }

  void invalidate(String cacheKey) => _box.delete(cacheKey);

  Future<void> invalidateByPrefix(String prefix) async {
    final keys = _box.keys.whereType<String>().where((k) => k.startsWith(prefix));
    for (final k in keys.toList(growable: false)) {
      await _box.delete(k);
    }
  }

  void clear() => _box.clear();

  _CachedEntry? _read(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;

    final version = raw['v']?.toString();
    final ts = raw['t'];
    final data = raw['d']?.toString();
    if (version == null || data == null) return null;
    if (version != _appVersion) return null;

    final epochMs = ts is int ? ts : int.tryParse(ts?.toString() ?? '');
    if (epochMs == null) return null;
    return _CachedEntry(epochMs: epochMs, json: data);
  }

  Future<void> _write(String key, Object jsonObj) async {
    final payload = jsonEncode(jsonObj);
    await _box.put(key, {
      'v': _appVersion,
      't': DateTime.now().millisecondsSinceEpoch,
      'd': payload,
    });
  }
}

class _CachedEntry {
  _CachedEntry({required this.epochMs, required this.json});

  final int epochMs;
  final String json;

  bool isExpired(Duration ttl) {
    final age = DateTime.now().millisecondsSinceEpoch - epochMs;
    return age > ttl.inMilliseconds;
  }

  T call<T>(T Function(Object json) decode) {
    final obj = jsonDecode(json);
    return decode(obj);
  }
}

