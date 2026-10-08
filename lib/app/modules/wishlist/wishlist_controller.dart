import 'dart:async';

import 'package:get/get.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/app_storage.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/price_formatter.dart';
import '../../data/models/price_sparkline.dart';
import '../../data/models/wishlist_item.dart';
import '../../data/repositories/bluebook_repository.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../add_collection/add_to_collection_launcher.dart';
import '../collection/collection_controller.dart';
import '../session/user_session_controller.dart';

/// The All / At target / Falling / Rising chips over the wishlist.
enum WishlistFilter {
  all('All'),
  atTarget('At target'),
  falling('Falling'),
  rising('Rising');

  const WishlistFilter(this.label);
  final String label;

  bool matches(WishlistItem item) {
    final change = item.changeSinceAdded ?? 0;
    return switch (this) {
      WishlistFilter.all => true,
      WishlistFilter.atTarget => item.atTarget,
      WishlistFilter.falling => change < 0,
      WishlistFilter.rising => change > 0,
    };
  }
}

/// The wishlist, shared by every screen that shows or changes it: the
/// Collection tab's Wishlist view, Home's card, the bookmark on market rows
/// and the bottle page. Registered once in AppBinding; it reloads when the
/// signed-in user changes.
class WishlistController extends GetxController {
  WishlistController({
    required WishlistRepository repo,
    required BluebookRepository bluebookRepo,
    required CollectionRepository collectionRepo,
  }) : _repo = repo,
       _bluebookRepo = bluebookRepo,
       _collectionRepo = collectionRepo;

  static WishlistController get to => Get.find<WishlistController>();

  final WishlistRepository _repo;
  final BluebookRepository _bluebookRepo;
  final CollectionRepository _collectionRepo;

  /// Newest first, as the server orders them.
  final items = <WishlistItem>[].obs;

  /// Bottle ids on the list, for the bookmarks.
  final wantedIds = <String>{}.obs;

  /// True until the first load for this user settles.
  final isLoading = true.obs;

  final filter = WishlistFilter.all.obs;

  /// 90-day price lines by bottle id, as on Market and Collection rows.
  final sparklines = <String, PriceSparkline>{}.obs;

  /// Bottle ids with a save or remove in flight, so a double tap is ignored.
  final _busy = <String>{};

  String? _userId;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<UserSessionController>()) {
      ever(Get.find<UserSessionController>().user, (_) {
        if (AppStorage.userId != _userId) unawaited(load());
      });
    }
    unawaited(load());
  }

  bool isWanted(String? bottleId) =>
      bottleId != null && wantedIds.contains(bottleId);

  WishlistItem? itemFor(String? bottleId) =>
      items.firstWhereOrNull((i) => i.bottleId == bottleId);

  List<WishlistItem> get filteredItems =>
      items.where(filter.value.matches).toList();

  // --- Summary figures ----------------------------------------------------

  /// What every priced bottle on the list costs at today's averages.
  double get totalNow =>
      items.fold(0, (sum, i) => sum + (i.currentPrice ?? 0));

  /// Move since added across the bottles that have both prices.
  double? get changeSinceAdded {
    var from = 0.0, now = 0.0;
    for (final i in items) {
      if (i.addedPrice == null || i.currentPrice == null) continue;
      from += i.addedPrice!;
      now += i.currentPrice!;
    }
    return from > 0 ? (now - from) / from * 100 : null;
  }

  int get atTargetCount => items.where((i) => i.atTarget).length;

  int get nearTargetCount => items.where((i) => i.nearTarget).length;

  /// Home's rows: bottles at their target first, then the biggest moves
  /// since added.
  List<WishlistItem> highlights({int limit = 3}) {
    int rank(WishlistItem i) => i.atTarget ? 0 : (i.nearTarget ? 1 : 2);
    final sorted = items.toList()
      ..sort((a, b) {
        final byRank = rank(a).compareTo(rank(b));
        if (byRank != 0) return byRank;
        return (b.changeSinceAdded ?? 0).abs().compareTo(
          (a.changeSinceAdded ?? 0).abs(),
        );
      });
    return sorted.take(limit).toList();
  }

  // --- Loading ------------------------------------------------------------

  Future<void> load({bool forceRefresh = false}) async {
    final userId = AppStorage.userId;
    if (userId != _userId) {
      _userId = userId;
      items.clear();
      wantedIds.clear();
      isLoading.value = true;
    }
    try {
      _apply(await _repo.all(forceRefresh: forceRefresh));
      unawaited(_loadSparklines(forceRefresh: forceRefresh));
    } catch (_) {
      // The list stays as it was; the views have nothing to retry with
      // except pull-to-refresh.
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forceReload() => load(forceRefresh: true);

  Future<void> _loadSparklines({bool forceRefresh = false}) async {
    final ids = [
      for (final i in items)
        if (i.currentPrice != null) i.bottleId,
    ];
    if (ids.isEmpty) return;
    sparklines.addAll(
      await _bluebookRepo.sparklines(ids, forceRefresh: forceRefresh),
    );
  }

  void _apply(List<WishlistItem> list) {
    items.assignAll(list);
    wantedIds
      ..clear()
      ..addAll(list.map((i) => i.bottleId));
  }

  // --- Changes ------------------------------------------------------------

  /// Adds the bottle, or updates its target and note. Returns the saved
  /// row, or null when it failed (the error has been shown).
  Future<WishlistItem?> save({
    required String bottleId,
    double? targetPrice,
    String? note,
    String source = 'sheet',
  }) async {
    if (!_busy.add(bottleId)) return null;
    final isNew = !isWanted(bottleId);
    try {
      final saved = await _repo.save(
        bottleId: bottleId,
        targetPrice: targetPrice,
        note: note,
      );
      final index = items.indexWhere((i) => i.bottleId == bottleId);
      if (index >= 0) {
        items[index] = saved;
      } else {
        items.insert(0, saved);
      }
      wantedIds.add(bottleId);
      _log(isNew ? 'wishlist_add' : 'wishlist_update', bottleId, {
        'source': source,
        'has_target': targetPrice != null ? 1 : 0,
      });
      if (isNew) unawaited(_loadSparklines());
      return saved;
    } on ApiException catch (e) {
      await AppSnackbar.error(e.message);
      return null;
    } catch (_) {
      await AppSnackbar.error("Couldn't update your wishlist. Try again.");
      return null;
    } finally {
      _busy.remove(bottleId);
    }
  }

  /// Takes the bottle off the list. Returns false when it failed.
  Future<bool> remove(String bottleId, {String source = 'sheet'}) async {
    if (!_busy.add(bottleId)) return false;
    final before = items.toList();
    items.removeWhere((i) => i.bottleId == bottleId);
    wantedIds.remove(bottleId);
    try {
      await _repo.remove(bottleId);
      _log('wishlist_remove', bottleId, {'source': source});
      return true;
    } catch (e) {
      _apply(before);
      await AppSnackbar.error(
        e is ApiException ? e.message : "Couldn't update your wishlist.",
      );
      return false;
    } finally {
      _busy.remove(bottleId);
    }
  }

  /// The market row's bookmark: adds without a target, or removes.
  Future<void> toggle(String bottleId, {String source = 'market_row'}) async {
    if (isWanted(bottleId)) {
      if (await remove(bottleId, source: source)) {
        await AppSnackbar.info('Removed from your wishlist');
      }
      return;
    }
    if (await save(bottleId: bottleId, source: source) != null) {
      await AppSnackbar.success('Added to your wishlist');
    }
  }

  /// Sets the target to [price], adding the bottle when it isn't on the
  /// list. Keeps the note.
  Future<void> setTarget(
    String bottleId,
    double price, {
    String source = 'deal_check',
  }) async {
    final saved = await save(
      bottleId: bottleId,
      targetPrice: price,
      note: itemFor(bottleId)?.note,
      source: source,
    );
    if (saved != null) {
      await AppSnackbar.success(
        'Target set: ${PriceFormatter.format(price.round().toString())}',
      );
    }
  }

  /// "I bought it": opens add-to-collection with the target (or today's
  /// price) as the price paid. Once it is saved the bottle leaves the
  /// wishlist and Collection shows the owned bottles.
  Future<void> markBought(WishlistItem item) async {
    _log('wishlist_bought', item.bottleId);
    final paid = item.targetPrice ?? item.currentPrice;
    final result = await AddToCollectionLauncher(_collectionRepo).open(
      bottleId: item.bottleId,
      name: item.bottle.bottleName,
      imagePathOrUrl: item.bottle.image,
      averageRaw: paid?.toStringAsFixed(2) ?? item.bottle.average,
      // Started from the Collection tab already. With this on, the add screen
      // pops straight to the shell and returns no result to act on.
      navigateToCollectionOnSuccess: false,
    );
    if (result != true) return;
    if (Get.isRegistered<CollectionController>()) {
      Get.find<CollectionController>().showOwned();
    }
    if (await remove(item.bottleId, source: 'bought')) {
      await AppSnackbar.success('Moved to your collection');
    }
  }

  void _log(String key, String bottleId, [Map<String, Object>? extra]) {
    if (!Get.isRegistered<AppAnalyticsController>()) return;
    unawaited(
      AppAnalyticsController.to.logTap(key, {
        'bottle_id': bottleId,
        ...?extra,
      }),
    );
  }
}
