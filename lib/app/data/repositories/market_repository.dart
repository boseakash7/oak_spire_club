import 'package:get/get.dart';

import '../../core/cache/app_cache.dart';
import '../datasources/market_remote_datasource.dart';
import '../models/market_models.dart';

/// Market overview, indexes, index detail and the Home tab's highlights.
///
/// The server recomputes these once a night, so an hour of client cache is
/// plenty; pull-to-refresh passes [forceRefresh]. The raw `data` maps are
/// cached and parsed on read, so a model change never needs a cache bust.
class MarketRepository {
  MarketRepository(this._remote);
  final MarketRemoteDataSource _remote;

  static const Duration _ttl = Duration(hours: 1);

  Future<MarketOverview> overview({
    int days = 30,
    bool forceRefresh = false,
  }) async {
    final raw = await Get.find<AppCache>().getOrFetch<Map<String, dynamic>>(
      cacheKey: 'market:overview:$days',
      ttl: _ttl,
      forceRefresh: forceRefresh,
      fetch: () => _remote.overview(days: days),
      encode: (v) => v,
      decode: _asMap,
    );
    return MarketOverview.fromJson(raw);
  }

  /// Every index that has values, headline first.
  Future<List<MarketIndexSummary>> indexes({bool forceRefresh = false}) async {
    final raw = await Get.find<AppCache>().getOrFetch<List<dynamic>>(
      cacheKey: 'market:indexes',
      ttl: _ttl,
      forceRefresh: forceRefresh,
      fetch: _remote.indexes,
      encode: (v) => v,
      decode: (json) => json is List ? json : const [],
    );
    return [for (final e in raw) ?MarketIndexSummary.fromJson(e)];
  }

  Future<MarketIndexDetail> indexDetail({
    required String slug,
    required int days,
    bool forceRefresh = false,
  }) async {
    final raw = await Get.find<AppCache>().getOrFetch<Map<String, dynamic>>(
      cacheKey: 'market:index:$slug:$days',
      ttl: _ttl,
      forceRefresh: forceRefresh,
      fetch: () => _remote.indexDetail(slug: slug, days: days),
      encode: (v) => v,
      decode: _asMap,
    );
    return MarketIndexDetail.fromJson(raw);
  }

  /// Breadth over [days] and the community lists. The server caches them
  /// for an hour too; collections change through the day, so this doesn't go
  /// longer.
  Future<MarketHighlights> highlights({
    int days = 30,
    bool forceRefresh = false,
  }) async {
    final raw = await Get.find<AppCache>().getOrFetch<Map<String, dynamic>>(
      cacheKey: 'market:highlights:$days',
      ttl: _ttl,
      forceRefresh: forceRefresh,
      fetch: () => _remote.highlights(days: days),
      encode: (v) => v,
      decode: _asMap,
    );
    return MarketHighlights.fromJson(raw);
  }

  static Map<String, dynamic> _asMap(Object json) =>
      json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{};
}
