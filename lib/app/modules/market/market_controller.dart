import 'dart:async';

import 'package:get/get.dart';

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
    await Future.wait([
      load(reset: true, showFullLoader: showFullLoader),
      loadCategories(forceRefresh: true),
      _loadLastUpdated(forceRefresh: true),
    ]);
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
