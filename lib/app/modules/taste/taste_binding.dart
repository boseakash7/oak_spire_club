import 'package:get/get.dart';

import '../../data/repositories/bluebook_repository.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/collection_repository.dart';
import 'taste_controller.dart';

class TasteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TasteController>(
      () => TasteController(
        bluebookRepo: Get.find<BluebookRepository>(),
        categoriesRepo: Get.find<CategoriesRepository>(),
        collectionRepo: Get.find<CollectionRepository>(),
      ),
    );
  }
}
