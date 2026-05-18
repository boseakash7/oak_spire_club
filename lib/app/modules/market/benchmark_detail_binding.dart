import 'package:get/get.dart';

import '../../data/repositories/bluebook_price_history_repository.dart';
import '../../data/repositories/collection_repository.dart';
import 'benchmark_detail_controller.dart';

class BenchmarkDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BenchmarkDetailController>(
      () => BenchmarkDetailController(
        collectionRepo: Get.find<CollectionRepository>(),
        priceHistoryRepo: Get.find<BluebookPriceHistoryRepository>(),
      ),
    );
  }
}
