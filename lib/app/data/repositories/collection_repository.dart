import 'package:get/get.dart';

import '../../core/cache/app_cache.dart';
import '../../core/storage/app_storage.dart';
import '../datasources/collection_remote_datasource.dart';
import '../models/collection_item_model.dart';

class CollectionRepository {
  CollectionRepository(this._remote);
  final CollectionRemoteDataSource _remote;

  static const Duration _ttl = Duration(hours: 24);
  static const int _defaultLookBackDays = 90;

  Future<void> addToCollection({
    required String bottleId,
    int quantity = 1,
    int fill = 100,
    double pricePaid = 0,
    String? image,
  }) async {
    final userId = AppStorage.userId;
    if (userId == null || userId.isEmpty) return;

    await _remote.add(
      bottleId: bottleId,
      userId: userId,
      type: CollectionType.normal,
      quantity: quantity,
      fill: fill,
      pricePaid: pricePaid,
      image: image,
    );

    // Invalidate cached home/collection data for this user.
    final cache = Get.find<AppCache>();
    await cache.invalidateByPrefix('collection:all:$userId');
    await cache.invalidateByPrefix('collection:chart:$userId:');
    // Ensure the most common chart key is included.
    cache.invalidate('collection:chart:$userId:$_defaultLookBackDays');
  }

  Future<List<CollectionItemModel>> fetchMyCollection({
    bool forceRefresh = false,
  }) async {
    final userId = AppStorage.userId;
    if (userId == null || userId.isEmpty) return [];
    final cache = Get.find<AppCache>();
    return cache.getOrFetch<List<CollectionItemModel>>(
      cacheKey: 'collection:all:$userId',
      ttl: _ttl,
      forceRefresh: forceRefresh,
      fetch: () => _remote.all(userId: userId, type: CollectionType.normal),
      encode: (list) => list.map((e) => e.toJson()).toList(),
      decode: (json) {
        if (json is! List) return <CollectionItemModel>[];
        return json
            .whereType<Map>()
            .map(
              (e) => CollectionItemModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      },
    );
  }

  Future<Map<String, dynamic>?> fetchChartData({
    int lookBackDays = _defaultLookBackDays,
    bool forceRefresh = false,
  }) async {
    final userId = AppStorage.userId;
    if (userId == null || userId.isEmpty) return null;
    final cache = Get.find<AppCache>();
    return cache.getOrFetch<Map<String, dynamic>>(
      cacheKey: 'collection:chart:$userId:$lookBackDays',
      ttl: _ttl,
      forceRefresh: forceRefresh,
      fetch: () =>
          _remote.chartData(userId: userId, lookBackDays: lookBackDays),
      encode: (m) => m,
      decode: (json) {
        if (json is Map<String, dynamic>) return json;
        if (json is Map) return Map<String, dynamic>.from(json);
        return <String, dynamic>{};
      },
    );
  }
}
