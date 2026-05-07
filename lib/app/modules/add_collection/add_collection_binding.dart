import 'package:get/get.dart';

import '../../data/repositories/bluebook_repository.dart';
import '../../data/repositories/collection_repository.dart';
import 'add_collection_controller.dart';

class AddCollectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddCollectionController>(
      () => AddCollectionController(
        bluebookRepo: Get.find<BluebookRepository>(),
        collectionRepo: Get.find<CollectionRepository>(),
      ),
    );
  }
}

