import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart';

import '../../core/cache/app_cache.dart';
import '../../core/storage/app_storage.dart';
import '../datasources/collection_remote_datasource.dart';
import '../models/collection_item_display.dart';
import '../models/collection_item_model.dart';

class CollectionRepository {
  CollectionRepository(this._remote);
  final CollectionRemoteDataSource _remote;

  static const Duration _ttl = Duration(hours: 24);
  static const int _defaultLookBackDays = 90;

  static String _groupKey(CollectionItemModel item) {
    final bbId = item.bluebook?['id']?.toString();
    if (bbId != null && bbId.isNotEmpty && bbId != 'null') return bbId;
    return item.id;
  }

  /// A fill as a percent. The API sends 1-100; a value of 1 or less is a
  /// fraction, the same rule [CollectionItemDisplay.fillRatio] applies.
  static double? _fillPercent(String? raw) {
    final v = double.tryParse(raw ?? '');
    if (v == null) return null;
    return v <= 1 ? v * 100 : v;
  }

  /// The bottles a row stands for: the ones it already carries, else one for
  /// the row itself (the server stores one row per bottle).
  static List<OwnedBottle> _bottlesOf(CollectionItemModel e) {
    final carried = e.bottles;
    if (carried != null) return carried;
    return [
      OwnedBottle(
        id: e.id,
        fill: (_fillPercent(e.fill) ?? 100).round().clamp(1, 100),
        pricePaid: double.tryParse(e.pricePaid ?? ''),
        createdAt: int.tryParse(e.createdAt ?? ''),
        dateAcquired: e.dateAcquired,
      ),
    ];
  }

  /// Merges the rows of one bluebook bottle into a single item, keeping each
  /// row as an [OwnedBottle].
  @visibleForTesting
  static List<CollectionItemModel> groupItems(List<CollectionItemModel> raw) {
    if (raw.isEmpty) return raw;

    final byBottle = <String, List<CollectionItemModel>>{};
    for (final item in raw) {
      final key = _groupKey(item);
      byBottle.putIfAbsent(key, () => <CollectionItemModel>[]).add(item);
    }

    final grouped = <CollectionItemModel>[];
    for (final entries in byBottle.values) {
      if (entries.length == 1) {
        final only = entries.first;
        grouped.add(
          only.bottles != null
              ? only
              : CollectionItemModel(
                  id: only.id,
                  type: only.type,
                  createdAt: only.createdAt,
                  quantity: only.quantity,
                  fill: only.fill,
                  image: only.image,
                  proof: only.proof,
                  pricePaid: only.pricePaid,
                  notes: only.notes,
                  dateAcquired: only.dateAcquired,
                  bluebook: only.bluebook,
                  priceMovement: only.priceMovement,
                  openedQuantity: only.openedQuantity,
                  bottles: _bottlesOf(only),
                ),
        );
        continue;
      }

      final base = entries.first;
      int totalQty = 0;
      // The merged fill is an average, so it can't say how many are open.
      int openedQty = 0;
      // Unit price weighted by quantity: 1 at $100 plus 3 at $200 is $175 a
      // bottle, not the $150 a plain average of the rows gives.
      double totalPaid = 0;
      int pricedQty = 0;
      // The fill is weighted the same way, so it is the average of every bottle.
      double fillSum = 0;
      int filledQty = 0;
      final bottles = <OwnedBottle>[];
      String? createdAt = base.createdAt;
      String? image = base.image;
      String? notes = base.notes;
      String? dateAcquired = base.dateAcquired;
      String? proof = base.proof;

      for (final e in entries) {
        final q = int.tryParse(e.quantity ?? '');
        final qty = (q == null || q <= 0) ? 1 : q;
        totalQty += qty;
        openedQty += e.openedBottleCount;
        bottles.addAll(_bottlesOf(e));

        final p = double.tryParse(e.pricePaid ?? '');
        if (p != null) {
          totalPaid += p * qty;
          pricedQty += qty;
        }

        final f = _fillPercent(e.fill);
        if (f != null) {
          fillSum += f * qty;
          filledQty += qty;
        }

        if ((proof == null || proof.isEmpty) &&
            (e.proof?.isNotEmpty ?? false)) {
          proof = e.proof;
        }
        if ((image == null || image.isEmpty) &&
            (e.image?.isNotEmpty ?? false)) {
          image = e.image;
        }
        if ((notes == null || notes.isEmpty) &&
            (e.notes?.isNotEmpty ?? false)) {
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
          fill: filledQty == 0
              ? base.fill
              : (fillSum / filledQty).round().toString(),
          image: image,
          proof: proof,
          pricePaid: pricedQty == 0
              ? base.pricePaid
              : (totalPaid / pricedQty).toStringAsFixed(2),
          notes: notes,
          dateAcquired: dateAcquired,
          bluebook: base.bluebook,
          priceMovement: base.priceMovement,
          openedQuantity: openedQty,
          bottles: bottles,
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
    File? imageFile,
    String? image,
    String? notes,
    String? dateAcquired,
    bool append = false,
  }) async {
    final userId = AppStorage.userId;
    if (userId == null || userId.isEmpty) return;

    await _remote.add(
      bottleId: bottleId,
      userId: userId,
      quantity: quantity,
      fill: fill,
      pricePaid: pricePaid,
      imageFile: imageFile,
      image: image,
      notes: notes,
      dateAcquired: dateAcquired,
      append: append,
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

    await _remote.deleteByUserBottle(bottleId: bottleId, userId: userId);

    final cache = Get.find<AppCache>();
    await cache.invalidateByPrefix('collection:all:$userId');
    await cache.invalidateByPrefix('collection:chart:$userId:');
    cache.invalidate('collection:chart:$userId:$_defaultLookBackDays');
  }

  /// Sets one bottle's fill. Value follows fill, so the chart is cleared
  /// along with the list.
  Future<void> updateBottleFill({
    required String rowId,
    required int fill,
  }) async {
    final userId = AppStorage.userId;
    if (userId == null || userId.isEmpty) return;

    await _remote.updateFill(
      rowId: rowId,
      userId: userId,
      fill: fill.clamp(1, 100),
    );
    final cache = Get.find<AppCache>();
    await cache.invalidateByPrefix('collection:all:$userId');
    await cache.invalidateByPrefix('collection:chart:$userId:');
    cache.invalidate('collection:chart:$userId:$_defaultLookBackDays');
  }

  /// Edits one bottle's price paid and purchase date; a null one is left as
  /// it is.
  Future<void> updateBottle({
    required String rowId,
    double? pricePaid,
    DateTime? purchasedOn,
  }) async {
    final userId = AppStorage.userId;
    if (userId == null || userId.isEmpty) return;

    await _remote.updateBottle(
      rowId: rowId,
      userId: userId,
      pricePaid: pricePaid,
      dateAcquired: purchasedOn == null
          ? null
          : OwnedBottle.formatPurchaseDate(purchasedOn),
    );
    final cache = Get.find<AppCache>();
    await cache.invalidateByPrefix('collection:all:$userId');
    await cache.invalidateByPrefix('collection:chart:$userId:');
    cache.invalidate('collection:chart:$userId:$_defaultLookBackDays');
  }

  /// Removes one bottle, leaving the others of the same kind alone.
  Future<void> removeBottle({required String rowId}) async {
    final userId = AppStorage.userId;
    if (userId == null || userId.isEmpty) return;

    await _remote.removeOne(rowId: rowId, userId: userId);

    final cache = Get.find<AppCache>();
    await cache.invalidateByPrefix('collection:all:$userId');
    await cache.invalidateByPrefix('collection:chart:$userId:');
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
      fetch: () async {
        final raw = await _remote.all(userId: userId);
        return groupItems(raw);
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
        return groupItems(decoded);
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
