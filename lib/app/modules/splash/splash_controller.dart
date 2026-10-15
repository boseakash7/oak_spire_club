import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/firebase/firebase_notification_topics.dart';
import '../../core/firebase/fcm_token_sync_service.dart';
import '../../core/services/app_update_service.dart';
import '../../core/storage/app_storage.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../modules/session/user_session_controller.dart';
import '../../routes/auth_navigation.dart';
import '../session/app_config_controller.dart';

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
    final configFuture = Get.find<AppConfigController>().refresh();

    await Future.wait([Future<void>.delayed(_minSplashVisible), configFuture]);

    final user = await userFuture;

    if (user == null) {
      unawaited(FirebaseNotificationTopics.syncUnregisteredTopic());
    }

    final canContinue = await _checkAppUpdate();
    if (!canContinue) return;

    isChecking.value = false;
    if (user == null) {
      AuthNavigation.openWelcome();
    } else {
      unawaited(FcmTokenSyncService.syncIfLoggedIn());
      AuthNavigation.completeSession(user);
    }
  }

  /// Forced: off to `/update-required` (returns false). Optional: the dialog,
  /// then on either way.
  Future<bool> _checkAppUpdate() => AppUpdateService.checkAtLaunch();

  Future<UserModel?> _resolveUser() async {
    await AppStorage.ensureReady();
    await AppStorage.repairUserIdFromUser();

    final local = _localUser();
    final id = AppStorage.userId ?? local?.id;

    if (kDebugMode) {
      debugPrint(
        '[Auth] Boot session userId=$id localUser=${local?.id} '
        'hasStoredUser=${AppStorage.user != null}',
      );
    }

    if (id == null || id.isEmpty) {
      return null;
    }

    if (local != null && !local.emailVerified) {
      return _requireVerifiedSession(local);
    }

    if (local != null && AppStorage.userId == null) {
      await AppStorage.saveSession(local.toJson());
    }

    try {
      final user = await _userRepo.refreshUserById(id);
      if (kDebugMode) {
        debugPrint('[Auth] Auto-login refreshed user_id=${user.id}');
      }
      return await _requireVerifiedSession(user);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Auth] Auto-login refresh failed, using cache: $e');
      }
      return _requireVerifiedSession(local ?? _localUser());
    }
  }

  /// Unverified accounts must not stay logged in across app restarts.
  Future<UserModel?> _requireVerifiedSession(UserModel? user) async {
    if (user == null) return null;
    if (user.emailVerified) return user;

    if (kDebugMode) {
      debugPrint('[Auth] Clearing unverified session user_id=${user.id}');
    }
    await AppStorage.clearSession();
    if (Get.isRegistered<UserSessionController>()) {
      Get.find<UserSessionController>().loadFromStorage();
    }
    return null;
  }

  UserModel? _localUser() {
    final json = AppStorage.user;
    if (json == null) return null;
    try {
      final user = UserModel.fromJson(json);
      if (user.id.isEmpty) return null;
      return user;
    } catch (_) {
      return null;
    }
  }
}
