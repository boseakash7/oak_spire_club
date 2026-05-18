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

  String _groupKey(CollectionItemModel item) {
    final bbId = item.bluebook?['id']?.toString();
    if (bbId != null && bbId.isNotEmpty && bbId != 'null') return bbId;
    return item.id;
  }

  List<CollectionItemModel> _groupCollectionItems(List<CollectionItemModel> raw) {
    if (raw.isEmpty) return raw;

    final byBottle = <String, List<CollectionItemModel>>{};
    for (final item in raw) {
      final key = _groupKey(item);
      byBottle.putIfAbsent(key, () => <CollectionItemModel>[]).add(item);
    }

    final grouped = <CollectionItemModel>[];
    for (final entries in byBottle.values) {
      if (entries.length == 1) {
        grouped.add(entries.first);
        continue;
      }

      final base = entries.first;
      int totalQty = 0;
      double totalPrice = 0;
      int priceCount = 0;
      double totalFill = 0;
      int fillCount = 0;
      String? createdAt = base.createdAt;
      String? image = base.image;
      String? notes = base.notes;
      String? dateAcquired = base.dateAcquired;

      for (final e in entries) {
        final q = int.tryParse(e.quantity ?? '');
        totalQty += (q == null || q <= 0) ? 1 : q;

        final p = double.tryParse(e.pricePaid ?? '');
        if (p != null) {
          totalPrice += p;
          priceCount += 1;
        }

        final f = double.tryParse(e.fill ?? '');
        if (f != null) {
          totalFill += f;
          fillCount += 1;
        }

        if ((image == null || image.isEmpty) && (e.image?.isNotEmpty ?? false)) {
          image = e.image;
        }
        if ((notes == null || notes.isEmpty) && (e.notes?.isNotEmpty ?? false)) {
          notes = e.notes;
        }
        if ((dateAcquired == null || dateAcquired.isEmpty) &&
            (e.dateAcquired?.isNotEmpty ?? false)) {
          dateAcquired = e.dateAcquired;
        }
        final c = int.tryParse(e.createdAt ?? '');
        final b = int.tryParse(createdAt ?? '');
        if (c != null && (b == null || c > b)) {
          createdAt = e.createdAt;
        }
      }

      grouped.add(
        CollectionItemModel(
          id: base.id,
          type: base.type,
          createdAt: createdAt,
          quantity: totalQty.toString(),
          fill: fillCount == 0
              ? base.fill
              : (totalFill / fillCount).round().toString(),
          image: image,
          proof: base.proof,
          pricePaid: priceCount == 0
              ? base.pricePaid
              : (totalPrice / priceCount).toStringAsFixed(2),
          notes: notes,
          dateAcquired: dateAcquired,
          bluebook: base.bluebook,
        ),
      );
    }

    return grouped;
  }

  Future<void> addToCollection({
    required String bottleId,
    int quantity = 1,
    int fill = 100,
    double pricePaid = 0,
    String? image,
    String? notes,
    String? dateAcquired,
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
      notes: notes,
      dateAcquired: dateAcquired,
    );

    // Invalidate cached home/collection data for this user.
    final cache = Get.find<AppCache>();
    await cache.invalidateByPrefix('collection:all:$userId');
    await cache.invalidateByPrefix('collection:chart:$userId:');
    // Ensure the most common chart key is included.
    cache.invalidate('collection:chart:$userId:$_defaultLookBackDays');
  }

  Future<void> removeFromCollection({required String bottleId}) async {
    final userId = AppStorage.userId;
    if (userId == null || userId.isEmpty) return;

    await _remote.deleteByUserBottle(
      bottleId: bottleId,
      userId: userId,
      type: CollectionType.normal,
    );

    final cache = Get.find<AppCache>();
    await cache.invalidateByPrefix('collection:all:$userId');
    await cache.invalidateByPrefix('collection:chart:$userId:');
    cache.invalidate('collection:chart:$userId:$_defaultLookBackDays');
  }

  Future<void> replaceCollectionItem({
    required String originalBottleId,
    required String bottleId,
    int quantity = 1,
    int fill = 100,
    double pricePaid = 0,
    String? image,
    String? notes,
    String? dateAcquired,
  }) async {
    final sameBottle = originalBottleId == bottleId;
    if (sameBottle) {
      await addToCollection(
        bottleId: bottleId,
        quantity: quantity,
        fill: fill,
        pricePaid: pricePaid,
        image: image,
        notes: notes,
        dateAcquired: dateAcquired,
      );
      return;
    }

    await addToCollection(
      bottleId: bottleId,
      quantity: quantity,
      fill: fill,
      pricePaid: pricePaid,
      image: image,
      notes: notes,
      dateAcquired: dateAcquired,
    );
    await removeFromCollection(bottleId: originalBottleId);
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
      fetch: () async {
        final raw = await _remote.all(userId: userId, type: CollectionType.normal);
        return _groupCollectionItems(raw);
      },
      encode: (list) => list.map((e) => e.toJson()).toList(),
      decode: (json) {
        if (json is! List) return <CollectionItemModel>[];
        final decoded = json
            .whereType<Map>()
            .map(
              (e) => CollectionItemModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
        return _groupCollectionItems(decoded);
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
