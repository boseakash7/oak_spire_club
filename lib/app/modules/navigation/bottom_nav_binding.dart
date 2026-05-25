import 'package:get/get.dart';

import '../collection/collection_controller.dart';
import '../home/home_controller.dart';
import '../market/market_controller.dart';
import 'bottom_nav_controller.dart';
import '../../data/repositories/bluebook_repository.dart';
import '../../data/repositories/categories_repository.dart';

class BottomNavBinding extends Bindings {
  @override
  void dependencies() {
    // fenix: shell tabs swap widgets; without it GetX deletes lazy controllers
    // when leaving a tab and Get.find fails on return (CollectionView Obx).
    Get.lazyPut<BottomNavController>(() => BottomNavController(), fenix: true);
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<CollectionController>(() => CollectionController(), fenix: true);
    Get.lazyPut<MarketController>(
      () => MarketController(
        bluebookRepo: Get.find<BluebookRepository>(),
        categoriesRepo: Get.find<CategoriesRepository>(),
      ),
      fenix: true,
    );
  }
}

