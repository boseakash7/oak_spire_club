import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/limit_exceeded_exception.dart';
import '../../data/models/subscription_package_model.dart';
import '../../data/repositories/package_repository.dart';

class SubscriptionController extends GetxController {
  final packages = <SubscriptionPackageModel>[].obs;
  final selectedPackageId = RxnString();
  final isLoadingPackages = true.obs;
  final loadError = RxnString();

  PackageRepository get _repo => Get.find<PackageRepository>();

  @override
  void onInit() {
    super.onInit();
    loadPackages();
  }

  Future<void> loadPackages() async {
    isLoadingPackages.value = true;
    loadError.value = null;
    try {
      final list = await _repo.getAll();
      list.sort((a, b) {
        if (a.isYearly == b.isYearly) {
          return a.displayPriceInt.compareTo(b.displayPriceInt);
        }
        return a.isYearly ? 1 : -1;
      });
      packages.assignAll(list);
      if (list.isEmpty) {
        selectedPackageId.value = null;
      } else if (selectedPackageId.value == null ||
          !list.any((p) => p.id == selectedPackageId.value)) {
        final monthly = list.where((p) => !p.isYearly).toList();
        selectedPackageId.value =
            monthly.isNotEmpty ? monthly.first.id : list.first.id;
      }
    } on LimitExceededException {
      packages.clear();
      selectedPackageId.value = null;
    } on ApiException catch (e) {
      packages.clear();
      selectedPackageId.value = null;
      loadError.value = e.message;
    } catch (e) {
      packages.clear();
      selectedPackageId.value = null;
      loadError.value = e.toString();
    } finally {
      isLoadingPackages.value = false;
    }
  }

  SubscriptionPackageModel? get selectedPackage {
    final id = selectedPackageId.value;
    if (id == null) return null;
    for (final p in packages) {
      if (p.id == id) return p;
    }
    return null;
  }

  void selectPackage(String id) => selectedPackageId.value = id;
}
