import 'dart:async';

import 'package:get/get.dart';

import '../../data/models/collection_item_display.dart';
import '../../data/models/collection_item_model.dart';
import '../../data/repositories/collection_repository.dart';
import '../../routes/app_routes.dart';
import '../collection/collection_controller.dart';
import '../home/home_controller.dart';
import '../navigation/bottom_nav_controller.dart';

/// Opens [AppRoutes.addToCollection] with the same collection lookup + prefill
/// flow used from Market benchmark detail (+ Add to collection).
class AddToCollectionLauncher {
  AddToCollectionLauncher(this._collectionRepo);

  final CollectionRepository _collectionRepo;

  Future<bool?> open({
    required String? bottleId,
    required String name,
    String? imagePathOrUrl,
    String? averageRaw,
    bool popBenchmarkDetailOnSuccess = false,
    bool navigateToCollectionOnSuccess = true,
  }) async {
    final selectedBottleId = bottleId?.trim();
    if (selectedBottleId == null ||
        selectedBottleId.isEmpty ||
        selectedBottleId == 'null') {
      return Get.toNamed(
        AppRoutes.addToCollection,
        arguments: {
          'prefill': {
            'name': name,
            'average': averageRaw,
            'image': imagePathOrUrl,
          },
        },
      );
    }

    final prefill = <String, dynamic>{
      'id': selectedBottleId,
      'name': name,
      'average': averageRaw,
      'image': imagePathOrUrl,
    };

    // Always a fresh add: the bottles already owned are left alone and the
    // new ones join them. Only the count is looked up, to say so on screen.
    final owned = await _ownedQuantity(selectedBottleId);
    prefill['quantity'] = 1;
    prefill['fill'] = 100;

    final result = await Get.toNamed(
      AppRoutes.addToCollection,
      arguments: {
        'ownedQuantity': owned,
        'navigateToCollectionOnSuccess': navigateToCollectionOnSuccess,
        'popBenchmarkDetailOnSuccess': popBenchmarkDetailOnSuccess,
        'prefill': prefill,
      },
    );

    if (result == true) {
      if (navigateToCollectionOnSuccess &&
          Get.isRegistered<BottomNavController>()) {
        Get.find<BottomNavController>().setIndex(
          BottomNavController.collectionTab,
        );
      }
      if (Get.isRegistered<HomeController>()) {
        unawaited(
          Get.find<HomeController>().fetchHomeData(forceRefresh: false),
        );
      }
      if (Get.isRegistered<CollectionController>()) {
        unawaited(Get.find<CollectionController>().forceReload());
      }
      if (popBenchmarkDetailOnSuccess &&
          Get.currentRoute == AppRoutes.benchmarkDetail) {
        Get.back();
      }
    }

    return result;
  }

  Future<int> _ownedQuantity(String bottleId) async {
    try {
      final all = await _collectionRepo.fetchMyCollection(forceRefresh: true);
      var total = 0;
      for (final item in all) {
        if (_resolveCollectionBottleId(item) == bottleId) {
          total += item.displayQuantity;
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  static String _resolveCollectionBottleId(CollectionItemModel item) {
    return item.bluebookBottleId ?? item.id;
  }
}
