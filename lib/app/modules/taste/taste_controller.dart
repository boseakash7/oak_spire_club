import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/app_snackbar.dart';
import '../../core/utils/dispose_after_detach.dart';
import '../../data/models/bluebook_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/bluebook_repository.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/collection_repository.dart';
import '../add_collection/add_to_collection_launcher.dart';

class TasteController extends GetxController {
  TasteController({
    required BluebookRepository bluebookRepo,
    required CategoriesRepository categoriesRepo,
    required CollectionRepository collectionRepo,
  })  : _bluebookRepo = bluebookRepo,
        _categoriesRepo = categoriesRepo,
        _collectionRepo = collectionRepo;

  final BluebookRepository _bluebookRepo;
  final CategoriesRepository _categoriesRepo;
  final CollectionRepository _collectionRepo;

  static const int _limit = 10;
  static const int _allCategoriesLimit = 200;

  final searchCtrl = TextEditingController();

  final bottles = <BluebookModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final selectedCategoryId = ''.obs;
  final keyword = ''.obs;

  int _page = 1;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadInitial());
  }

  @override
  void onClose() {
    _debounce?.cancel();
    disposeAfterDetach([searchCtrl]);
    super.onClose();
  }

  Future<void> loadInitial() async {
    await Future.wait([
      load(reset: true),
      _loadCategories(),
    ]);
  }

  Future<void> load({required bool reset, bool showFullLoader = true}) async {
    if (reset) {
      _page = 1;
      hasMore.value = true;
      if (showFullLoader) {
        isLoading.value = true;
      }
    } else {
      if (!hasMore.value || isLoadingMore.value) return;
      isLoadingMore.value = true;
      _page += 1;
    }

    try {
      final res = await _bluebookRepo.search(
        page: _page,
        limit: _limit,
        keyword: keyword.value.trim().isEmpty ? null : keyword.value.trim(),
        categoryId: _apiCategoryId,
      );
      if (reset) {
        bottles.assignAll(res);
      } else {
        bottles.addAll(res);
      }
      hasMore.value = res.length >= _limit;
    } catch (e) {
      if (!reset) _page -= 1;
      await AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> forceReload({bool showFullLoader = true}) async {
    await Future.wait([
      load(reset: true, showFullLoader: showFullLoader),
      _loadCategories(forceRefresh: true),
    ]);
  }

  Future<void> loadMore() => load(reset: false);

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_applySearch(value));
    });
  }

  Future<void> _applySearch(String value) async {
    keyword.value = value;
    await forceReload(showFullLoader: false);
  }

  Future<void> _loadCategories({bool forceRefresh = false}) async {
    try {
      final page = await _categoriesRepo.list(
        page: 1,
        limit: _allCategoriesLimit,
        forceRefresh: forceRefresh,
      );
      categories.assignAll(page.items);
    } catch (_) {
      // Category chips optional; bluebook list still works.
    }
  }

  void selectCategory(String id) {
    if (selectedCategoryId.value == id) return;
    selectedCategoryId.value = id;
    unawaited(load(reset: true, showFullLoader: false));
  }

  /// Sent as query `category_id` on `bluebook/get-all-bluebooks` when not All.
  String? get _apiCategoryId {
    final id = selectedCategoryId.value.trim();
    return id.isEmpty ? null : id;
  }

  List<BluebookModel> get visibleBottles =>
      bottles.toList(growable: false);

  /// Same flow as Market benchmark detail (+ Add to collection).
  Future<bool?> addBottleToCollection(BluebookModel bottle) {
    return AddToCollectionLauncher(_collectionRepo).open(
      bottleId: bottle.id,
      name: bottle.bottleName,
      imagePathOrUrl: bottle.image,
      averageRaw: bottle.average,
    );
  }
}
