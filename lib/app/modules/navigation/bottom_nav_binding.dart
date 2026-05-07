import 'package:get/get.dart';

import '../collection/collection_controller.dart';
import '../home/home_controller.dart';
import '../market/market_controller.dart';
import 'bottom_nav_controller.dart';
import '../../data/repositories/categories_repository.dart';

class BottomNavBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BottomNavController>(() => BottomNavController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<CollectionController>(() => CollectionController());
    Get.lazyPut<MarketController>(
      () => MarketController(repo: Get.find<CategoriesRepository>()),
    );
  }
}

