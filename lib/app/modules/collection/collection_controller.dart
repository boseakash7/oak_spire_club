import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/models/collection_item_display.dart';
import '../../data/models/collection_item_model.dart';
import '../../data/repositories/collection_repository.dart';

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

      final chart = await _repo.fetchChartData(
        lookBackDays: 90,
        forceRefresh: forceRefresh,
      );
      if (chart != null) {
        final first = double.tryParse(chart['first_price']?.toString() ?? '');
        final last = double.tryParse(chart['last_price']?.toString() ?? '');
        final fmt = NumberFormat.currency(
          locale: 'en_US',
          symbol: r'$',
          decimalDigits: 0,
        );
        if (last != null) {
          valueText.value = fmt.format(last);
        }
        if (first != null && last != null && first != 0) {
          final pct = ((last - first) / first) * 100;
          trendShort.value =
              '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';
        }
      }
    } catch (_) {
      // Leave placeholders; optional: surface via snackbar on retry only.
    } finally {
      isLoading.value = false;
    }
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
}
