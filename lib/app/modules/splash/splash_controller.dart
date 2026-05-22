import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/storage/app_storage.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../routes/app_routes.dart';
import '../../routes/auth_navigation.dart';

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
    final userFuture = _resolveUser();

    await Future.delayed(_minSplashVisible);
    final user = await userFuture;

    isChecking.value = false;
    if (user == null) {
      Get.offAllNamed(AppRoutes.signUp);
    } else {
      AuthNavigation.completeSession(user);
    }
  }

  Future<UserModel?> _resolveUser() async {
    final id = AppStorage.userId;
    if (id == null || id.isEmpty) {
      return null;
    }
    if (kDebugMode) {
      debugPrint('[Auth] Auto-login stored user_id=$id');
    }

    try {
      final user = await _userRepo.refreshUserById(id);
      if (kDebugMode) {
        debugPrint('[Auth] Auto-login refreshed user_id=${user.id}');
      }
      return user;
    } catch (_) {
      await AppStorage.clearUserId();
      await AppStorage.clearUser();
      return null;
    }
  }
}
