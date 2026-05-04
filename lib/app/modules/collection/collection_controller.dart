import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/models/collection_item_display.dart';
import '../../data/models/collection_item_model.dart';
import '../../data/repositories/collection_repository.dart';

enum CollectionFilter { all, opened, notOpened, rareFind }

class CollectionController extends GetxController {
  CollectionController();

  final items = <CollectionItemModel>[].obs;
  final filter = CollectionFilter.all.obs;
  final isLoading = true.obs;

  final valueText = r'$ —'.obs;
  final trendShort = '—'.obs;

  final _repo = Get.find<CollectionRepository>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final list = await _repo.fetchMyCollection();
      items.assignAll(list);

      final chart = await _repo.fetchChartData(lookBackDays: 90);
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

  void setFilter(CollectionFilter value) => filter.value = value;

  List<CollectionItemModel> get filteredItems {
    final f = filter.value;
    if (f == CollectionFilter.all) return items.toList();
    return items.where((e) => _matches(e, f)).toList();
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
