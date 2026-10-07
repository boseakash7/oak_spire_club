import 'dart:async';

import 'package:get/get.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../data/models/bluebook_model.dart';
import '../../data/models/market_models.dart';
import '../../data/models/price_sparkline.dart';
import '../../data/repositories/bluebook_repository.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/market_repository.dart';
import '../shared/paged_bottle_search.dart';

/// Browse order for the market list; [apiValue] is the server's `sort`.
enum MarketSort {
  name('name', 'Name'),
  priceDesc('price_desc', 'Price: high to low'),
  priceAsc('price_asc', 'Price: low to high'),
  gain30d('gain_30d', 'Biggest 30-day rise'),
  loss30d('loss_30d', 'Biggest 30-day fall'),
  premium('premium', 'Premium over retail');

  const MarketSort(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// The Market tab: the Oak Spire indexes and the paged, sortable bottle list.
/// The biggest movers are on Home.
class MarketController extends GetxController with PagedBottleSearch {
  MarketController({
    required BluebookRepository bluebookRepo,
    required CategoriesRepository categoriesRepo,
    required MarketRepository marketRepo,
  }) : _bluebookRepo = bluebookRepo,
       _categoriesRepo = categoriesRepo,
       _marketRepo = marketRepo;

  final BluebookRepository _bluebookRepo;
  final CategoriesRepository _categoriesRepo;
  final MarketRepository _marketRepo;

  /// The headline index, which the strip falls back to when `market/indexes`
  /// has none; null until it loads or when the server has none (an older
  /// server, or before the nightly job's first run).
  final overview = Rxn<MarketOverview>();

  /// Every index with values, headline first, for the index strip.
  final indexes = <MarketIndexSummary>[].obs;

  final sort = MarketSort.name.obs;

  @override
  String? get sortParam => sort.value.apiValue;

  @override
  BluebookRepository get bluebookRepo => _bluebookRepo;

  @override
  CategoriesRepository get categoriesRepo => _categoriesRepo;

  /// "Updated 10.05.2026"; empty until it loads.
  final lastUpdatedText = ''.obs;

  /// 90-day sparklines keyed by bottle id, filled in page by page.
  final sparklines = <String, PriceSparkline>{}.obs;

  /// A pull-to-refresh bypasses the per-bottle sparkline cache for the pages
  /// it reloads.
  bool _refreshSparklines = false;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadInitial());
  }

  @override
  void onClose() {
    disposeSearch();
    super.onClose();
  }

  Future<void> loadInitial() async {
    await Future.wait([
      load(reset: true),
      loadCategories(),
      _loadLastUpdated(),
      _loadMarket(),
    ]);
  }

  Future<void> forceReload({bool showFullLoader = true}) async {
    _refreshSparklines = true;
    await Future.wait([
      load(reset: true, showFullLoader: showFullLoader),
      loadCategories(forceRefresh: true),
      _loadLastUpdated(forceRefresh: true),
      _loadMarket(forceRefresh: true),
    ]);
  }

  void setSort(MarketSort value) {
    if (sort.value == value) return;
    sort.value = value;
    _logTap('market_sort_select', {'sort': value.apiValue});
    unawaited(load(reset: true, showFullLoader: false));
  }

  /// Overview and indexes are optional: a failure (or an older server
  /// without them) leaves the list screen as it was.
  Future<void> _loadMarket({bool forceRefresh = false}) async {
    await Future.wait([
      _marketRepo
          .overview(forceRefresh: forceRefresh)
          .then((o) {
            overview.value = o.isEmpty ? null : o;
          })
          .catchError((_) {}),
      _marketRepo
          .indexes(forceRefresh: forceRefresh)
          .then(indexes.assignAll)
          .catchError((_) {}),
    ]);
  }

  void _logTap(String key, Map<String, Object> params) {
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(AppAnalyticsController.to.logTap(key, params));
    }
  }

  /// One sparklines request per page, for the bottles that have a price.
  @override
  void onBottlesLoaded(List<BluebookModel> page, {required bool reset}) {
    final ids = [
      for (final b in page)
        if ((double.tryParse(b.average ?? '') ?? 0) > 0) b.id,
    ];
    final forceRefresh = _refreshSparklines && reset;
    if (reset) _refreshSparklines = false;
    if (ids.isEmpty) return;
    unawaited(
      _bluebookRepo
          .sparklines(ids, forceRefresh: forceRefresh)
          .then(sparklines.addAll),
    );
  }

  Future<void> _loadLastUpdated({bool forceRefresh = false}) async {
    try {
      final readable = await _bluebookRepo.lastUpdatedReadable(
        forceRefresh: forceRefresh,
      );
      lastUpdatedText.value = readable != null && readable.trim().isNotEmpty
          ? 'Updated ${readable.trim()}'
          : 'Updated recently';
    } catch (_) {
      lastUpdatedText.value = 'Updated recently';
    }
  }
}
