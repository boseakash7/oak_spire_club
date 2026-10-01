import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/utils/app_snackbar.dart';
import '../../core/utils/dispose_after_detach.dart';
import '../../data/models/bluebook_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/bluebook_repository.dart';
import '../../data/repositories/categories_repository.dart';

/// Paged bottle search with category chips, shared by the Benchmark tab and
/// the "add a bottle" browser (taste).
///
/// With a keyword the repository searches (`bluebook/search`: ranked,
/// typo tolerant); without one it browses. Either way [selectedCategoryId]
/// filters. Each reset bumps a generation, and a response for an older one is
/// dropped, so a slow earlier query never overwrites a newer one's results.
mixin PagedBottleSearch on GetxController {
  BluebookRepository get bluebookRepo;
  CategoriesRepository get categoriesRepo;

  static const int pageSize = 10;
  static const int _allCategoriesLimit = 200;
  static const Duration _debounceDelay = Duration(milliseconds: 400);

  final bottles = <BluebookModel>[].obs;
  final categories = <CategoryModel>[].obs;

  /// First load (skeleton).
  final isLoading = true.obs;

  /// A new query / category is loading while the old list stays visible.
  final isSearching = false.obs;

  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final keyword = ''.obs;
  final selectedCategoryId = ''.obs;

  /// Owned here so clearing the query from an empty state clears the field.
  final searchCtrl = TextEditingController();

  int _page = 1;
  int _generation = 0;
  Timer? _debounce;

  List<BluebookModel> get visibleBottles => bottles.toList(growable: false);

  /// Call from [onClose]. The field may still be on screen during the pop
  /// transition, so its controller is disposed once it has detached.
  void disposeSearch() {
    _debounce?.cancel();
    disposeAfterDetach([searchCtrl]);
  }

  Future<void> load({required bool reset, bool showFullLoader = true}) async {
    final generation = reset ? ++_generation : _generation;
    if (reset) {
      _page = 1;
      hasMore.value = true;
      if (showFullLoader) {
        isLoading.value = true;
      } else {
        isSearching.value = true;
      }
    } else {
      if (!hasMore.value || isLoadingMore.value || isSearching.value) return;
      isLoadingMore.value = true;
      _page += 1;
    }

    try {
      final query = keyword.value.trim();
      final category = selectedCategoryId.value.trim();
      final res = await bluebookRepo.search(
        page: _page,
        limit: pageSize,
        keyword: query.isEmpty ? null : query,
        categoryId: category.isEmpty ? null : category,
      );
      if (generation != _generation) return;
      if (reset) {
        bottles.assignAll(res);
      } else {
        bottles.addAll(res);
      }
      hasMore.value = res.length >= pageSize;
    } catch (e) {
      if (generation != _generation) return;
      if (!reset) _page -= 1;
      await AppSnackbar.error(e.toString());
    } finally {
      if (generation == _generation) {
        isLoading.value = false;
        isSearching.value = false;
        isLoadingMore.value = false;
      }
    }
  }

  Future<void> loadMore() => load(reset: false);

  Future<void> loadCategories({bool forceRefresh = false}) async {
    try {
      final page = await categoriesRepo.list(
        page: 1,
        limit: _allCategoriesLimit,
        forceRefresh: forceRefresh,
      );
      categories.assignAll(page.items);
    } catch (_) {
      // The chips are optional; the list still works without them.
    }
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () => unawaited(_applySearch(value)));
  }

  Future<void> _applySearch(String value) async {
    if (keyword.value.trim() == value.trim()) return;
    keyword.value = value;
    await load(reset: true, showFullLoader: false);
  }

  /// Empty state's "Clear search".
  void clearSearch() {
    _debounce?.cancel();
    searchCtrl.clear();
    unawaited(_applySearch(''));
  }

  void selectCategory(String id) {
    if (selectedCategoryId.value == id) return;
    selectedCategoryId.value = id;
    unawaited(load(reset: true, showFullLoader: false));
  }
}
