import 'dart:async';

import 'package:get/get.dart';

import '../../data/models/bluebook_model.dart';
import '../../data/repositories/bluebook_repository.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/collection_repository.dart';
import '../add_collection/add_to_collection_launcher.dart';
import '../shared/paged_bottle_search.dart';

/// "Add a bottle": search the catalog and add a bottle to the collection.
class TasteController extends GetxController with PagedBottleSearch {
  TasteController({
    required BluebookRepository bluebookRepo,
    required CategoriesRepository categoriesRepo,
    required CollectionRepository collectionRepo,
  }) : _bluebookRepo = bluebookRepo,
       _categoriesRepo = categoriesRepo,
       _collectionRepo = collectionRepo;

  final BluebookRepository _bluebookRepo;
  final CategoriesRepository _categoriesRepo;
  final CollectionRepository _collectionRepo;

  @override
  BluebookRepository get bluebookRepo => _bluebookRepo;

  @override
  CategoriesRepository get categoriesRepo => _categoriesRepo;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadInitial());
  }

  @override
  void onClose() {
    disposeSearch();
    super.onClose();
  }

  Future<void> loadInitial() async {
    await Future.wait([load(reset: true), loadCategories()]);
  }

  Future<void> forceReload({bool showFullLoader = true}) async {
    await Future.wait([
      load(reset: true, showFullLoader: showFullLoader),
      loadCategories(forceRefresh: true),
    ]);
  }

  /// Same flow as the bottle detail's "Add to collection".
  Future<bool?> addBottleToCollection(BluebookModel bottle) {
    return AddToCollectionLauncher(_collectionRepo).open(
      bottleId: bottle.id,
      name: bottle.bottleName,
      imagePathOrUrl: bottle.image,
      averageRaw: bottle.average,
    );
  }
}
