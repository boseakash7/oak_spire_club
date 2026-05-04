import 'package:get/get.dart';

import '../../core/storage/app_storage.dart';
import '../../data/repositories/user_repository.dart';
import '../../routes/app_routes.dart';

class SplashController extends GetxController {
  final isChecking = true.obs;

  final _userRepo = Get.find<UserRepository>();

  /// Visible splash window (~3–4s): always hold at least this, longer if boot/API is slower.
  static const Duration _minSplashVisible = Duration(milliseconds: 3600);

  @override
  void onReady() {
    super.onReady();
    _boot();
  }

  Future<void> _boot() async {
    final routeFuture = _resolveRoute();

    await Future.delayed(_minSplashVisible);
    final route = await routeFuture;

    isChecking.value = false;
    Get.offAllNamed(route);
  }

  Future<String> _resolveRoute() async {
    final id = AppStorage.userId;
    if (id == null || id.isEmpty) {
      return AppRoutes.signUp;
    }

    try {
      await _userRepo.refreshUserById(id);
      return AppRoutes.shell;
    } catch (_) {
      await AppStorage.clearUserId();
      await AppStorage.clearUser();
      return AppRoutes.signUp;
    }
  }
}

