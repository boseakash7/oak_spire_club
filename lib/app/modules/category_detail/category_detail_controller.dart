import 'package:get/get.dart';

import '../../core/utils/app_snackbar.dart';
import '../../data/models/category_detail_model.dart';
import '../../data/repositories/categories_repository.dart';

class CategoryDetailController extends GetxController {
  CategoryDetailController({
    required CategoriesRepository repo,
    required this.categoryId,
    this.initialName,
  }) : _repo = repo;

  final CategoriesRepository _repo;
  final String categoryId;
  final String? initialName;

  final isLoading = true.obs;
  final detail = Rxn<CategoryDetailModel>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      detail.value = await _repo.detail(categoryId: categoryId);
    } catch (e) {
      await AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

