import 'package:get/get.dart';

import '../../core/utils/app_snackbar.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/categories_repository.dart';

class MarketController extends GetxController {
  MarketController({required CategoriesRepository repo}) : _repo = repo;
  final CategoriesRepository _repo;

  static const int _limit = 10;

  final categories = <CategoryModel>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;

  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    load(reset: true);
  }

  Future<void> load({required bool reset}) async {
    if (reset) {
      _page = 1;
      hasMore.value = true;
      isLoading.value = true;
    } else {
      if (!hasMore.value || isLoadingMore.value) return;
      isLoadingMore.value = true;
      _page += 1;
    }

    try {
      final res = await _repo.list(page: _page, limit: _limit);
      if (reset) {
        categories.assignAll(res.items);
      } else {
        categories.addAll(res.items);
      }
      hasMore.value = res.currentPage < res.totalPages;
    } catch (e) {
      if (!reset) _page -= 1;
      await AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> forceReload() => load(reset: true);
  Future<void> loadMore() => load(reset: false);
}

