import 'package:get/get.dart';

import '../../core/storage/app_storage.dart';
import '../../data/repositories/config_repository.dart';

class AppConfigController extends GetxController {
  final uploadUrl = RxnString();
  final pourImagePlaceholderUrl = RxnString();

  ConfigRepository get _repo => Get.find<ConfigRepository>();

  @override
  void onInit() {
    super.onInit();
    loadFromStorage();
    refresh();
  }

  void loadFromStorage() {
    uploadUrl.value = AppStorage.uploadUrl;
    pourImagePlaceholderUrl.value = AppStorage.pourImagePlaceholderUrl;
  }

  @override
  Future<void> refresh() async {
    try {
      await _repo.refresh();
    } catch (_) {
      // Ignore config failure; app can still run with fallbacks.
    } finally {
      loadFromStorage();
    }
  }
}

