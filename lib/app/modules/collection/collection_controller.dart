import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/collection_value_calculator.dart';
import '../../data/models/collection_item_display.dart';
import '../../data/models/collection_item_model.dart';
import '../../data/repositories/collection_repository.dart';
import '../home/home_controller.dart';

enum CollectionFilter { all, opened, notOpened, rareFind }

enum CollectionSort { name, price, fillRate, addedTime }

class CollectionController extends GetxController {
  CollectionController();

  final items = <CollectionItemModel>[].obs;
  final filter = CollectionFilter.all.obs;
  final isLoading = true.obs;

  final valueText = r'$ —'.obs;
  final trendShort = '—'.obs;

  final sort = CollectionSort.name.obs;
  final sortAscending = true.obs;

  final _repo = Get.find<CollectionRepository>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load({bool forceRefresh = false}) async {
    isLoading.value = true;
    try {
      final list = await _repo.fetchMyCollection(forceRefresh: forceRefresh);
      items.assignAll(list);

      final fmt = NumberFormat.currency(
        locale: 'en_US',
        symbol: r'$',
        decimalDigits: 0,
      );
      final localTotal =
          CollectionValueCalculator.totalInvestedFromItems(list);

      final chart = await _repo.fetchChartData(
        lookBackDays: 90,
        forceRefresh: forceRefresh,
      );
      if (chart != null) {
        final first = double.tryParse(chart['first_price']?.toString() ?? '');
        final last = double.tryParse(chart['last_price']?.toString() ?? '');
        if (localTotal > 0) {
          valueText.value = fmt.format(localTotal);
        } else {
          valueText.value = r'$ —';
        }
        if (list.isEmpty) {
          trendShort.value = '—';
        } else if (first != null && last != null && last != 0) {
          final pct = CollectionValueCalculator.movedPercentFromFirstLast(
            first: first,
            last: last,
          )!;
          trendShort.value =
              '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%';
        } else {
          trendShort.value = '—';
        }
      } else {
        _applyFallbackValue(list, fmt);
      }
      _syncHomeAfterCollectionLoad();
    } catch (_) {
      _applyFallbackValue(
        items,
        NumberFormat.currency(
          locale: 'en_US',
          symbol: r'$',
          decimalDigits: 0,
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _syncHomeAfterCollectionLoad() {
    if (!Get.isRegistered<HomeController>()) return;
    unawaited(
      Get.find<HomeController>().fetchHomeData(forceRefresh: false),
    );
  }

  void _applyFallbackValue(
    Iterable<CollectionItemModel> list,
    NumberFormat formatter,
  ) {
    final total = CollectionValueCalculator.totalInvestedFromItems(list);
    valueText.value =
        total > 0 ? formatter.format(total) : r'$ —';
    trendShort.value = '—';
  }

  Future<void> forceReload() => load(forceRefresh: true);

  void setFilter(CollectionFilter value) => filter.value = value;

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
    final list = (f == CollectionFilter.all)
        ? items.toList()
        : items.where((e) => _matches(e, f)).toList();

    list.sort(_compare);
    return list;
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
        final pa = double.tryParse(a.pricePaid ?? '') ?? 0;
        final pb = double.tryParse(b.pricePaid ?? '') ?? 0;
        res = pa.compareTo(pb);
        break;
      case CollectionSort.fillRate:
        res = a.fillRatio.compareTo(b.fillRatio);
        break;
      case CollectionSort.addedTime:
        final da = DateTime.tryParse(a.createdAt ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse(b.createdAt ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        res = da.compareTo(db);
        break;
    }

    return asc ? res : -res;
  }

  bool _matches(CollectionItemModel e, CollectionFilter f) {
    switch (f) {
      case CollectionFilter.all:
        return true;
      case CollectionFilter.opened:
        return e.isOpenedHeuristic;
      case CollectionFilter.notOpened:
        return !e.isOpenedHeuristic;
      case CollectionFilter.rareFind:
        return e.isRareFind;
    }
  }

  String resolveBottleId(CollectionItemModel item) {
    final bbId = item.bluebook?['id']?.toString();
    if (bbId != null && bbId.isNotEmpty && bbId != 'null') return bbId;
    return item.id;
  }

  Future<void> increaseBottleQuantity(
    CollectionItemModel item,
    int quantity, {
    bool reloadList = true,
  }) async {
    await _repo.addToCollection(
      bottleId: resolveBottleId(item),
      quantity: quantity,
      fill: (item.fillRatio * 100).round().clamp(0, 100),
      pricePaid: double.tryParse(item.pricePaid ?? '') ?? 0,
      image: item.image,
    );
    if (reloadList) await forceReload();
  }

  Future<void> decreaseBottleQuantity(
    CollectionItemModel item,
    int quantity, {
    bool reloadList = true,
  }) async {
    if (quantity <= 0) {
      await _repo.removeFromCollection(bottleId: resolveBottleId(item));
    } else {
      await _repo.addToCollection(
        bottleId: resolveBottleId(item),
        quantity: quantity,
        fill: (item.fillRatio * 100).round().clamp(0, 100),
        pricePaid: double.tryParse(item.pricePaid ?? '') ?? 0,
        image: item.image,
      );
    }
    if (reloadList) await forceReload();
  }
}
