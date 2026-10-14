import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/collection_value_calculator.dart';
import '../../data/models/collection_item_display.dart';
import '../../data/models/collection_item_model.dart';
import '../../data/models/price_sparkline.dart';
import '../../data/repositories/bluebook_repository.dart';
import '../../core/analytics/app_analytics_controller.dart';
import '../../core/utils/rating_formatter.dart';
import '../../data/repositories/collection_repository.dart';
import '../../routes/app_routes.dart';
import '../home/home_controller.dart';

/// What the All bottles list shows. Each value is one of the Collection tab's
/// quick-stat tiles and matches the bottles that tile counts (see
/// [CollectionValueCalculator.holdingCounts] for the last four).
enum CollectionFilter {
  all('All bottles', 'All'),
  drunk('Drunk', 'Drunk'),
  rated('Rated', 'Rated'),
  rare('Rare', 'Rare'),
  duplicates('Duplicates', 'Duplicates'),
  doubled('Doubled', 'Doubled'),
  gaining('Gaining value', 'Gaining'),
  losing('Losing value', 'Losing');

  const CollectionFilter(this.label, this.chipLabel);

  /// The list's title while this filter is on.
  final String label;

  /// The filter's chip on the All bottles list.
  final String chipLabel;

  bool matches(CollectionItemModel item) {
    switch (this) {
      case CollectionFilter.all:
        return true;
      case CollectionFilter.drunk:
        return item.isDrunk;
      case CollectionFilter.rated:
        return RatingFormatter.outOfTen(item.ratingRaw) != null;
      case CollectionFilter.rare:
        return item.isRareFind;
      case CollectionFilter.duplicates:
        return item.displayQuantity > 1;
      case CollectionFilter.doubled:
        return (item.gainPercent ?? 0) >= 100;
      case CollectionFilter.gaining:
        return (item.gainPercent ?? 0) > 0;
      case CollectionFilter.losing:
        return (item.gainPercent ?? 0) < 0;
    }
  }
}

enum CollectionSort { name, price, gain, fillRate, addedTime }

/// The Collection tab's two views: the bottles owned, or the wishlist.
enum CollectionSegment { owned, wishlist }

final _wholeDollars = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 0,
);

class CollectionController extends GetxController {
  CollectionController();

  final items = <CollectionItemModel>[].obs;
  final filter = CollectionFilter.all.obs;
  final isLoading = true.obs;

  /// The All bottles search, matched on name, brand, distillery, type and
  /// region, on top of [filter].
  final searchCtrl = TextEditingController();
  final query = ''.obs;

  /// What the collection is worth today (see
  /// [CollectionValueCalculator.summarize]), for the count-up animation.
  final valueAmount = 0.0.obs;

  /// True when no bottle has a market price, so [valueAmount] is what was
  /// paid and the heading must say so.
  final showingInvestedAsValue = false.obs;

  /// "Invested $X · +$Y · 2 at cost" under the value; empty when unknown.
  final valueCaption = ''.obs;

  /// Gain against what was paid, over the bottles that have a market price.
  final gainPercent = Rxn<double>();

  /// [gainPercent] as a badge label, e.g. `+27.7%`.
  final trendShort = '—'.obs;

  /// Owned or Wishlist, switched at the top of the tab.
  final segment = CollectionSegment.owned.obs;

  final sort = CollectionSort.name.obs;
  final sortAscending = true.obs;

  /// 90-day sparklines keyed by bluebook id; rows without one draw a
  /// placeholder until it lands (or for good, if the bottle has no price).
  final sparklines = <String, PriceSparkline>{}.obs;

  final _repo = Get.find<CollectionRepository>();
  final _bluebookRepo = Get.find<BluebookRepository>();

  /// The skeleton shows only until the first load lands; later refreshes
  /// (pull-to-refresh, quantity edits, returning from add) keep the list on
  /// screen and swap the data in place.
  bool _loadedOnce = false;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }

  Future<void> load({bool forceRefresh = false}) async {
    if (!_loadedOnce) isLoading.value = true;
    try {
      final list = await _repo.fetchMyCollection(forceRefresh: forceRefresh);
      items.assignAll(list);
      _applyValueFigures(list);
      unawaited(_loadSparklines(list, forceRefresh: forceRefresh));
      _syncHomeAfterCollectionLoad();
    } catch (_) {
      _applyValueFigures(items);
    } finally {
      _loadedOnce = true;
      isLoading.value = false;
    }
  }

  /// One request for every bottle in the collection (cached per bottle).
  Future<void> _loadSparklines(
    List<CollectionItemModel> list, {
    bool forceRefresh = false,
  }) async {
    final ids = [
      for (final item in list)
        if (item.bluebookBottleId != null && item.marketAverageValue != null)
          item.bluebookBottleId!,
    ];
    if (ids.isEmpty) return;
    final fetched = await _bluebookRepo.sparklines(
      ids,
      forceRefresh: forceRefresh,
    );
    sparklines.addAll(fetched);
  }

  void _applyValueFigures(Iterable<CollectionItemModel> list) {
    final summary = CollectionValueCalculator.summarize(list);
    valueAmount.value = summary.value;
    showingInvestedAsValue.value = summary.showingInvestedAsValue;

    final pct = summary.gainPercent;
    gainPercent.value = pct;
    trendShort.value = pct == null
        ? '—'
        : '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';

    final gain = summary.gain;
    valueCaption.value = [
      if (!summary.showingInvestedAsValue && summary.invested > 0)
        'Invested ${_wholeDollars.format(summary.invested)}',
      if (gain != null)
        '${gain >= 0 ? '+' : '-'}${_wholeDollars.format(gain.abs())}',
      if (summary.valuedAtCostCount > 0) '${summary.valuedAtCostCount} at cost',
    ].join(' · ');
  }

  /// Keeps Home's figures in step without flashing its skeleton.
  void _syncHomeAfterCollectionLoad() {
    if (!Get.isRegistered<HomeController>()) return;
    unawaited(
      Get.find<HomeController>().fetchHomeData(
        forceRefresh: false,
        background: true,
      ),
    );
  }

  Future<void> forceReload() => load(forceRefresh: true);

  void setSegment(CollectionSegment value) {
    if (segment.value == value) return;
    segment.value = value;
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(
        AppAnalyticsController.to.logTap('collection_segment', {
          'segment': value.name,
        }),
      );
    }
  }

  void showOwned() => segment.value = CollectionSegment.owned;

  void showWishlist() => segment.value = CollectionSegment.wishlist;

  /// Opens the All bottles list showing [value]'s bottles: a quick-stat
  /// tile, or "View all bottles" for every one.
  void openBottles([CollectionFilter value = CollectionFilter.all]) {
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(
        AppAnalyticsController.to.logTap('collection_view_all', {
          'filter': value.name,
        }),
      );
    }
    filter.value = value;
    clearSearch();
    Get.toNamed(AppRoutes.collectionBottles);
  }

  void onSearchChanged(String value) => query.value = value.trim();

  void clearSearch() {
    searchCtrl.clear();
    query.value = '';
  }

  void setFilter(CollectionFilter value) => filter.value = value;

  /// Back to every bottle: the no-results state.
  void clearFilter() => filter.value = CollectionFilter.all;

  bool get hasActiveSort =>
      sort.value != CollectionSort.name || !sortAscending.value;

  void toggleSort(CollectionSort field) {
    if (sort.value == field) {
      sortAscending.value = !sortAscending.value;
    } else {
      sort.value = field;
      sortAscending.value = true;
    }
  }

  List<CollectionItemModel> get filteredItems {
    final f = filter.value;
    final words = query.value
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final list = items
        .where(f.matches)
        .where((item) => words.isEmpty || _matchesSearch(item, words))
        .toList();

    list.sort(_compare);
    return list;
  }

  /// Every word must appear somewhere in the bottle's name or catalog facts.
  static bool _matchesSearch(CollectionItemModel item, List<String> words) {
    final d = item.details;
    final haystack = [
      item.lineTitle,
      d.brand,
      d.distillery,
      d.spiritType,
      d.region,
    ].whereType<String>().join(' ').toLowerCase();
    return words.every(haystack.contains);
  }

  int _compare(CollectionItemModel a, CollectionItemModel b) {
    final asc = sortAscending.value;
    final field = sort.value;

    int res;
    switch (field) {
      case CollectionSort.name:
        res = a.lineTitle.toLowerCase().compareTo(b.lineTitle.toLowerCase());
        break;
      case CollectionSort.price:
        // Today's value per bottle, or what was paid when there is none.
        final pa =
            a.marketAverageValue ?? double.tryParse(a.pricePaid ?? '') ?? 0;
        final pb =
            b.marketAverageValue ?? double.tryParse(b.pricePaid ?? '') ?? 0;
        res = pa.compareTo(pb);
        break;
      case CollectionSort.gain:
        // Bottles without a gain figure sort as if flat.
        res = (a.gainPercent ?? 0).compareTo(b.gainPercent ?? 0);
        break;
      case CollectionSort.fillRate:
        res = a.fillRatio.compareTo(b.fillRatio);
        break;
      case CollectionSort.addedTime:
        final da =
            DateTime.tryParse(a.createdAt ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db =
            DateTime.tryParse(b.createdAt ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        res = da.compareTo(db);
        break;
    }

    return asc ? res : -res;
  }

  String resolveBottleId(CollectionItemModel item) {
    final bbId = item.bluebook?['id']?.toString();
    if (bbId != null && bbId.isNotEmpty && bbId != 'null') return bbId;
    return item.id;
  }

  /// The merged item for [bottleId] as of the last load, or null once gone.
  CollectionItemModel? itemFor(String bottleId) {
    for (final item in items) {
      if (resolveBottleId(item) == bottleId) return item;
    }
    return null;
  }

  /// Adds one sealed bottle to [item], leaving the ones it has alone. The
  /// [quantity] is the count after the add, as the quick view's stepper has it.
  Future<void> increaseBottleQuantity(
    CollectionItemModel item,
    int quantity, {
    bool reloadList = true,
  }) async {
    await _repo.addToCollection(
      bottleId: resolveBottleId(item),
      quantity: 1,
      fill: 100,
      pricePaid: double.tryParse(item.pricePaid ?? '') ?? 0,
      image: item.image,
      append: true,
    );
    if (reloadList) await forceReload();
  }

  /// Removes the most recently added bottle of [item], or all of it once
  /// [quantity] reaches zero.
  Future<void> decreaseBottleQuantity(
    CollectionItemModel item,
    int quantity, {
    bool reloadList = true,
  }) async {
    final newest = _newestBottle(item);
    if (quantity <= 0) {
      await _repo.removeFromCollection(bottleId: resolveBottleId(item));
    } else if (newest != null) {
      await _repo.removeBottle(rowId: newest.id);
    }
    if (reloadList) await forceReload();
  }

  static OwnedBottle? _newestBottle(CollectionItemModel item) {
    OwnedBottle? newest;
    for (final b in item.bottles ?? const <OwnedBottle>[]) {
      if (newest == null ||
          (b.createdAt ?? 0) > (newest.createdAt ?? 0) ||
          ((b.createdAt ?? 0) == (newest.createdAt ?? 0) &&
              (int.tryParse(b.id) ?? 0) > (int.tryParse(newest.id) ?? 0))) {
        newest = b;
      }
    }
    return newest;
  }

  /// Sets one bottle's fill. The list is not reloaded: the caller keeps its
  /// own copy and the list catches up when it next loads.
  Future<void> setBottleFill(OwnedBottle bottle, int fill) =>
      _repo.updateBottleFill(rowId: bottle.id, fill: fill);

  /// Saves one bottle's price paid and purchase date (a null one is kept),
  /// then reloads, because the merged item's paid price and gain
  /// follow the price.
  Future<void> editBottle(
    OwnedBottle bottle, {
    double? pricePaid,
    DateTime? purchasedOn,
  }) async {
    await _repo.updateBottle(
      rowId: bottle.id,
      pricePaid: pricePaid,
      purchasedOn: purchasedOn,
    );
    await forceReload();
  }

  /// An opened bottle is one under 100%, so opening starts just below it.
  static const int openedFill = 99;

  Future<void> openBottle(OwnedBottle bottle) =>
      setBottleFill(bottle, openedFill);

  Future<void> sealBottle(OwnedBottle bottle) => setBottleFill(bottle, 100);
}
