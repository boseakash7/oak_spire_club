import 'package:get/get.dart';

import '../../data/repositories/bluebook_repository.dart';
import '../../data/repositories/market_repository.dart';
import 'market_index_controller.dart';

class MarketIndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MarketIndexController>(
      () => MarketIndexController(
        marketRepo: Get.find<MarketRepository>(),
        bluebookRepo: Get.find<BluebookRepository>(),
      ),
    );
  }
}
