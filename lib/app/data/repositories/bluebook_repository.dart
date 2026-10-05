import 'package:get/get.dart';

import '../../core/cache/app_cache.dart';
import '../datasources/bluebook_remote_datasource.dart';
import '../models/bluebook_model.dart';
import '../models/price_sparkline.dart';

class BluebookRepository {
  BluebookRepository(this._remote);
  final BluebookRemoteDataSource _remote;
  static const Duration _ttl = Duration(hours: 24);

  /// Prices move once a night, so a sparkline is good for hours.
  static const Duration _sparklineTtl = Duration(hours: 6);

  Future<List<BluebookModel>> search({
    required int page,
    required int limit,
    String? keyword,
    String? categoryId,
  }) =>
      _remote.getAll(
        page: page,
        limit: limit,
        keyword: keyword,
        categoryId: categoryId,
      );

  Future<BluebookModel> getById(String id) => _remote.getById(id);

  Future<BluebookModel> create({
    required String bottleName,
    required String bottlePrice,
    required String userId,
  }) =>
      _remote.create(
        bottleName: bottleName,
        bottlePrice: bottlePrice,
        userId: userId,
      );

  /// Sparklines for [ids], keyed by id. Cached per bottle
  /// (`bluebook:spark:$id:$days`), and only the misses are requested, in one
  /// call per [BluebookRemoteDataSource.sparklinesMaxIds]. A bottle the
  /// server has no price for is cached as empty, so it is not asked for again.
  ///
  /// Never throws: a sparkline is decoration, and a server without the
  /// endpoint should cost the rows their sparklines and nothing else.
  Future<Map<String, PriceSparkline>> sparklines(
    Iterable<String> ids, {
    int days = 90,
    bool forceRefresh = false,
  }) async {
    final cache = Get.find<AppCache>();
    String key(String id) => 'bluebook:spark:$id:$days';

    final out = <String, PriceSparkline>{};
    final missing = <String>[];
    for (final id in ids.toSet()) {
      if (id.isEmpty) continue;
      final cached = forceRefresh
          ? null
          : cache.peek<PriceSparkline>(
              cacheKey: key(id),
              ttl: _sparklineTtl,
              decode: (json) => PriceSparkline.fromJson(
                json is Map ? Map<String, dynamic>.from(json) : const {},
              ),
            );
      if (cached == null) {
        missing.add(id);
      } else if (!cached.isEmpty) {
        out[id] = cached;
      }
    }

    const chunk = BluebookRemoteDataSource.sparklinesMaxIds;
    for (var i = 0; i < missing.length; i += chunk) {
      final batch = missing.sublist(
        i,
        i + chunk > missing.length ? missing.length : i + chunk,
      );
      try {
        final fetched = await _remote.sparklines(ids: batch, days: days);
        for (final id in batch) {
          final spark = fetched[id] ?? const PriceSparkline(prices: []);
          await cache.put(key(id), spark.toJson());
          if (!spark.isEmpty) out[id] = spark;
        }
      } catch (_) {
        // Keep what we have; these rows draw the placeholder baseline.
      }
    }
    return out;
  }

  Future<String?> lastUpdatedReadable({bool forceRefresh = false}) {
    final cache = Get.find<AppCache>();
    return cache.getOrFetch<String?>(
      cacheKey: 'bluebook:last-updated',
      ttl: _ttl,
      forceRefresh: forceRefresh,
      fetch: _remote.getLastUpdatedReadable,
      encode: (v) => <String, dynamic>{'readable': v},
      decode: (json) {
        if (json is Map<String, dynamic>) {
          return json['readable']?.toString();
        }
        if (json is Map) {
          return json['readable']?.toString();
        }
        return null;
      },
    );
  }
}

