import 'dart:async';

import 'package:get/get.dart';

import '../../core/storage/app_storage.dart';
import '../../data/models/bluebook_model.dart';
import '../../data/models/collection_item_display.dart';
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

  /// Enough rows under the chips that a filter visibly changes the list.
  @override
  int get pageSize => 12;

  /// Bluebook ids already in the user's collection.
  final ownedBottleIds = <String>{}.obs;

  /// Latest queries that led to a bottle being opened, newest first.
  final recentSearches = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    recentSearches.assignAll(AppStorage.recentBottleSearches);
    unawaited(loadInitial());
  }

  @override
  void onClose() {
    disposeSearch();
    super.onClose();
  }

  Future<void> loadInitial() async {
    await Future.wait([load(reset: true), loadCategories(), loadOwned()]);
  }

  Future<void> forceReload({bool showFullLoader = true}) async {
    await Future.wait([
      load(reset: true, showFullLoader: showFullLoader),
      loadCategories(forceRefresh: true),
      loadOwned(forceRefresh: true),
    ]);
  }

  Future<void> loadOwned({bool forceRefresh = false}) async {
    try {
      final items = await _collectionRepo.fetchMyCollection(
        forceRefresh: forceRefresh,
      );
      ownedBottleIds.assignAll({
        for (final item in items) item.bluebookBottleId ?? item.id,
      });
    } catch (_) {
      // The "In your collection" label is a hint; the list works without it.
    }
  }

  bool isOwned(BluebookModel bottle) => ownedBottleIds.contains(bottle.id);

  /// The loaded bottles, with an exact name match first, then names that
  /// start with the query, then the server's order.
  @override
  List<BluebookModel> get visibleBottles {
    final list = bottles.toList(growable: false);
    final q = keyword.value.trim().toLowerCase();
    if (q.isEmpty) return list;
    int rank(BluebookModel b) {
      final name = b.bottleName.trim().toLowerCase();
      if (name == q) return 0;
      if (name.startsWith(q)) return 1;
      return 2;
    }

    final indexed = [for (var i = 0; i < list.length; i++) (i, list[i])];
    indexed.sort((a, b) {
      final byRank = rank(a.$2).compareTo(rank(b.$2));
      return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2];
  }

  /// Remembers the current query once it has led somewhere.
  void rememberSearch() {
    final q = keyword.value.trim();
    if (q.length < 2) return;
    unawaited(AppStorage.addRecentBottleSearch(q));
    recentSearches.assignAll([
      q,
      ...recentSearches.where((e) => e.toLowerCase() != q.toLowerCase()),
    ].take(6));
  }

  Future<void> clearRecentSearches() async {
    recentSearches.clear();
    await AppStorage.clearRecentBottleSearches();
  }

  /// Same flow as the bottle detail's "Add to collection".
  Future<bool?> addBottleToCollection(BluebookModel bottle) {
    rememberSearch();
    return AddToCollectionLauncher(_collectionRepo).open(
      bottleId: bottle.id,
      name: bottle.bottleName,
      imagePathOrUrl: bottle.image,
      averageRaw: bottle.average,
    );
  }
}
