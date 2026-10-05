import 'dart:async';

import 'package:get/get.dart';

import '../../data/models/bluebook_model.dart';
import '../../data/models/price_sparkline.dart';
import '../../data/repositories/bluebook_repository.dart';
import '../../data/repositories/categories_repository.dart';
import '../shared/paged_bottle_search.dart';

/// The Benchmark tab: paged bottle search plus the "last updated" label.
class MarketController extends GetxController with PagedBottleSearch {
  MarketController({
    required BluebookRepository bluebookRepo,
    required CategoriesRepository categoriesRepo,
  }) : _bluebookRepo = bluebookRepo,
       _categoriesRepo = categoriesRepo;

  final BluebookRepository _bluebookRepo;
  final CategoriesRepository _categoriesRepo;

  @override
  BluebookRepository get bluebookRepo => _bluebookRepo;

  @override
  CategoriesRepository get categoriesRepo => _categoriesRepo;

  final lastUpdatedText = 'Loading...'.obs;

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
    ]);
  }

  Future<void> forceReload({bool showFullLoader = true}) async {
    _refreshSparklines = true;
    await Future.wait([
      load(reset: true, showFullLoader: showFullLoader),
      loadCategories(forceRefresh: true),
      _loadLastUpdated(forceRefresh: true),
    ]);
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
