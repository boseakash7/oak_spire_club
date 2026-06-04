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

    final matches = await _findCollectionMatches(selectedBottleId);

    if (matches.isNotEmpty) {
      var totalQty = 0;
      var totalPrice = 0.0;
      var totalFill = 0.0;
      var fillCount = 0;
      String? image;
      String? notes;
      String? dateAcquired;

      for (final item in matches) {
        final q = int.tryParse(item.quantity ?? '');
        totalQty += (q == null || q <= 0) ? 1 : q;
        totalPrice += double.tryParse(item.pricePaid ?? '') ?? 0;
        final fill = int.tryParse(item.fill ?? '');
        if (fill != null) {
          totalFill += fill;
          fillCount += 1;
        }
        image ??= item.image;
        notes ??= item.notes;
        dateAcquired ??= item.dateAcquired;
      }

      prefill['quantity'] = totalQty <= 0 ? 1 : totalQty;
      prefill['average'] = (totalPrice / matches.length).toStringAsFixed(2);
      if (fillCount > 0) {
        prefill['fill'] = (totalFill / fillCount).round().clamp(1, 100);
      }
      if (image != null && image.isNotEmpty) prefill['image'] = image;
      if (notes != null && notes.isNotEmpty) prefill['notes'] = notes;
      if (dateAcquired != null && dateAcquired.isNotEmpty) {
        prefill['date_acquired'] = dateAcquired;
      }
    } else {
      prefill['quantity'] = 1;
      prefill['fill'] = 100;
    }

    final result = await Get.toNamed(
      AppRoutes.addToCollection,
      arguments: {
        if (matches.isNotEmpty) 'editMode': true,
        if (matches.isNotEmpty) 'originalBottleId': selectedBottleId,
        'navigateToCollectionOnSuccess': navigateToCollectionOnSuccess,
        'popBenchmarkDetailOnSuccess': popBenchmarkDetailOnSuccess,
        'prefill': prefill,
      },
    );

    if (result == true) {
      if (navigateToCollectionOnSuccess &&
          Get.isRegistered<BottomNavController>()) {
        Get.find<BottomNavController>().setIndex(1);
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

  Future<List<CollectionItemModel>> _findCollectionMatches(
    String bottleId,
  ) async {
    try {
      final all = await _collectionRepo.fetchMyCollection(forceRefresh: true);
      return all
          .where((item) => _resolveCollectionBottleId(item) == bottleId)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static String _resolveCollectionBottleId(CollectionItemModel item) {
    return item.bluebookBottleId ?? item.id;
  }
}
