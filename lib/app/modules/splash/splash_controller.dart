import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../core/firebase/firebase_notification_topics.dart';
import '../../core/services/app_store_launcher.dart';
import '../../core/services/app_update_checker.dart';
import '../../core/storage/app_storage.dart';
import '../../core/widgets/app_update_dialog.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
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
      AuthNavigation.completeSession(user);
    }
  }

  Future<bool> _checkAppUpdate() async {
    final config = Get.find<AppConfigController>();
    final result = await AppUpdateChecker.evaluate(config.currentVersion.value);
    if (!result.needsUpdate) return true;

    final context = Get.context;
    if (context == null || !context.mounted) return true;

    if (Get.isRegistered<AppAnalyticsController>()) {
      AppAnalyticsController.to.logTap('app_update_prompt');
    }

    return showAppUpdateDialog(
      context,
      isForced: result.isForced,
      onUpdate: () {
        if (Get.isRegistered<AppAnalyticsController>()) {
          AppAnalyticsController.to.logTap('app_update_confirm');
        }
        AppStoreLauncher.openStoreListing();
      },
    ).then((continueApp) {
      if (continueApp) {
        if (Get.isRegistered<AppAnalyticsController>()) {
          AppAnalyticsController.to.logTap('app_update_later');
        }
      }
      return continueApp;
    });
  }

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

    if (local != null && AppStorage.userId == null) {
      await AppStorage.saveSession(local.toJson());
    }

    try {
      final user = await _userRepo.refreshUserById(id);
      if (kDebugMode) {
        debugPrint('[Auth] Auto-login refreshed user_id=${user.id}');
      }
      return user;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Auth] Auto-login refresh failed, using cache: $e');
      }
      return local ?? _localUser();
    }
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
