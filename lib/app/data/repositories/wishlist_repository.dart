import 'package:get/get.dart';

import '../../core/cache/app_cache.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/app_storage.dart';
import '../datasources/wishlist_remote_datasource.dart';
import '../models/wishlist_item.dart';

/// The signed-in user's wishlist. The list is cached for a day under
/// `wishlist:all:$userId`; every change clears it. Without a user it is empty
/// and changes do nothing.
class WishlistRepository {
  WishlistRepository(this._remote);
  final WishlistRemoteDataSource _remote;

  static const Duration _ttl = Duration(hours: 24);

  String _key(String userId) => 'wishlist:all:$userId';

  Future<List<WishlistItem>> all({bool forceRefresh = false}) async {
    final userId = AppStorage.userId;
    if (userId == null || userId.isEmpty) return const [];
    final raw = await Get.find<AppCache>().getOrFetch<List<dynamic>>(
      cacheKey: _key(userId),
      ttl: _ttl,
      forceRefresh: forceRefresh,
      fetch: () => _remote.all(userId: userId),
      encode: (v) => v,
      decode: (json) => json is List ? json : const [],
    );
    return [for (final e in raw) ?WishlistItem.fromJson(e)];
  }

  /// Adds [bottleId], or updates its target and note; returns the saved row.
  Future<WishlistItem> save({
    required String bottleId,
    double? targetPrice,
    String? note,
  }) async {
    final userId = _requireUser();
    final row = await _remote.save(
      userId: userId,
      bottleId: bottleId,
      targetPrice: targetPrice,
      note: note,
    );
    Get.find<AppCache>().invalidate(_key(userId));
    final item = WishlistItem.fromJson(row);
    if (item == null) throw ApiException('Unexpected server response.');
    return item;
  }

  Future<void> remove(String bottleId) async {
    final userId = _requireUser();
    await _remote.remove(userId: userId, bottleId: bottleId);
    Get.find<AppCache>().invalidate(_key(userId));
  }

  String _requireUser() {
    final userId = AppStorage.userId;
    if (userId == null || userId.isEmpty) {
      throw ApiException('Sign in to keep a wishlist.');
    }
    return userId;
  }
}
