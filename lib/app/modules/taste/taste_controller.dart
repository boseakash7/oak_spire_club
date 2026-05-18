import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/app_snackbar.dart';
import '../../data/models/category_bottle_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/categories_repository.dart';

class TasteController extends GetxController {
  TasteController({
    required CategoriesRepository categoriesRepo,
  }) : _categoriesRepo = categoriesRepo;

  final CategoriesRepository _categoriesRepo;

  final searchCtrl = TextEditingController();

  final isLoading = true.obs;
  final categories = <CategoryModel>[].obs;
  final selectedCategoryId = ''.obs; // '' => All

  final _bottlesByCategoryId = <String, List<CategoryBottleModel>>{}.obs;
  final _allBottles = <CategoryBottleModel>[].obs;
  final _query = ''.obs;

  static const int _allCategoriesLimit = 200;

  @override
  void onInit() {
    super.onInit();
    searchCtrl.addListener(_onSearchChanged);
    load();
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }

  void _onSearchChanged() => _query.value = searchCtrl.text.trim().toLowerCase();

  Future<void> load({bool forceRefresh = false}) async {
    isLoading.value = true;
    try {
      final page = await _categoriesRepo.list(
        page: 1,
        limit: _allCategoriesLimit,
        forceRefresh: forceRefresh,
      );
      categories.assignAll(page.items);

      final details = await Future.wait(
        page.items.map(
          (c) => _categoriesRepo.detail(
            categoryId: c.id,
            forceRefresh: forceRefresh,
          ),
        ),
      );

      final mapped = <String, List<CategoryBottleModel>>{};
      final all = <CategoryBottleModel>[];
      final seenBottleIds = <String>{};

      for (final d in details) {
        mapped[d.category.id] = d.bottles;
        for (final b in d.bottles) {
          if (seenBottleIds.add(b.id)) {
            all.add(b);
          }
        }
      }

      _bottlesByCategoryId.assignAll(mapped);
      _allBottles.assignAll(all);
    } catch (e) {
      await AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(String id) => selectedCategoryId.value = id;

  Future<void> forceReload() => load(forceRefresh: true);

  List<CategoryBottleModel> get visibleBottles {
    final selected = selectedCategoryId.value;
    final base = selected.isEmpty
        ? _allBottles
        : (_bottlesByCategoryId[selected] ?? const <CategoryBottleModel>[]);
    final q = _query.value;
    if (q.isEmpty) return base.toList();
    return base
        .where((b) => b.bottleName.toLowerCase().contains(q))
        .toList(growable: false);
  }

}

