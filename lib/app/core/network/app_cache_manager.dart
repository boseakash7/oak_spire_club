import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// App-wide cache managers.
///
/// We use a JSON-backed repository to avoid sqflite channel issues on some setups.
class AppCacheManager {
  AppCacheManager._();

  static final CacheManager images = CacheManager(
    Config(
      'oakspire_images',
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 600,
      repo: JsonCacheInfoRepository(databaseName: 'oakspire_images'),
    ),
  );
}

