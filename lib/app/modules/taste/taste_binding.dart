import 'package:get/get.dart';

import '../../data/repositories/categories_repository.dart';
import 'taste_controller.dart';

class TasteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TasteController>(
      () => TasteController(categoriesRepo: Get.find<CategoriesRepository>()),
    );
  }
}

