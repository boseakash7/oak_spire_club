import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../modules/session/app_config_controller.dart';
import '../../routes/app_routes.dart';
import '../analytics/app_analytics_controller.dart';
import '../widgets/app_update_dialog.dart';
import 'app_store_launcher.dart';
import 'app_update_checker.dart';

/// Runs the update rule from `config/all`:
/// - **Forced** (below the minimum build): `/update-required`, a screen with
///   nothing behind it. Checked at launch and again when the app comes back to
///   the foreground (at most every [_resumeInterval]), so a long-lived session
///   is caught too.
/// - **Optional** (below the latest build): the update dialog, once per launch.
///   "Later" lasts until the app is closed; nothing is stored.
abstract final class AppUpdateService {
  AppUpdateService._();

  static const Duration _resumeInterval = Duration(hours: 6);

  static _ResumeObserver? _observer;
  static DateTime? _lastCheck;
  static bool _optionalShown = false;

  /// Starts the foreground re-check. Called once from `AppBinding`.
  static void start() {
    if (_observer != null) return;
    _observer = _ResumeObserver();
    WidgetsBinding.instance.addObserver(_observer!);
  }

  /// At launch, after config has refreshed. Returns false when the app must
  /// not go on (it has been sent to `/update-required`).
  static Future<bool> checkAtLaunch() async {
    _lastCheck = DateTime.now();
    final result = await AppUpdateChecker.evaluate(
      Get.find<AppConfigController>().currentVersion.value,
    );

    if (result.isForced) {
      _openRequired(result);
      return false;
    }
    if (result.needsUpdate && !_optionalShown) {
      _optionalShown = true;
      await _offer(result);
    }
    return true;
  }

  /// Back in the foreground: refresh config and block if this build has fallen
  /// below the minimum since launch.
  static Future<void> _checkOnResume() async {
    if (Get.currentRoute == AppRoutes.splash ||
        Get.currentRoute == AppRoutes.updateRequired) {
      return;
    }
    final last = _lastCheck;
    if (last != null && DateTime.now().difference(last) < _resumeInterval) {
      return;
    }
    _lastCheck = DateTime.now();

    final config = Get.find<AppConfigController>();
    await config.refresh();
    final result = await AppUpdateChecker.evaluate(config.currentVersion.value);
    if (result.isForced) _openRequired(result);
  }

  static void _openRequired(AppUpdateCheckResult result) {
    _log('app_update_required');
    Get.offAllNamed(AppRoutes.updateRequired, arguments: result);
  }

  static Future<void> _offer(AppUpdateCheckResult result) async {
    final context = Get.context;
    if (context == null || !context.mounted) return;

    _log('app_update_prompt');
    final update = await showAppUpdateDialog(
      context,
      versionName: result.versionName,
      notes: result.notes,
    );
    if (update) {
      _log('app_update_confirm');
      unawaited(AppStoreLauncher.openStoreListing());
    } else {
      _log('app_update_later');
    }
  }

  static void _log(String key) {
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(AppAnalyticsController.to.logTap(key));
    }
  }
}

class _ResumeObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(AppUpdateService._checkOnResume());
    }
  }
}
