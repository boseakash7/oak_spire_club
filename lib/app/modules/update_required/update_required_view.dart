import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/services/app_store_launcher.dart';
import '../../core/services/app_update_checker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_backdrop_image.dart';
import '../../core/widgets/common_primary_button.dart';
import '../../routes/app_routes.dart';
import '../session/app_config_controller.dart';

/// The forced update: this build is below the server's minimum, so the app
/// can't go on. Reached with `Get.offAllNamed`, so there is nothing behind it;
/// Back leaves the app.
///
/// Coming back to the foreground re-checks, so if the minimum is lowered again
/// the app goes on through splash. (Installing the update restarts the app.)
///
/// Takes an [AppUpdateCheckResult] as its argument, for the version names.
class UpdateRequiredView extends StatefulWidget {
  const UpdateRequiredView({super.key});

  @override
  State<UpdateRequiredView> createState() => _UpdateRequiredViewState();
}

class _UpdateRequiredViewState extends State<UpdateRequiredView>
    with WidgetsBindingObserver {
  final AppUpdateCheckResult? _result = Get.arguments is AppUpdateCheckResult
      ? Get.arguments as AppUpdateCheckResult
      : null;

  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_recheck());
  }

  Future<void> _recheck() async {
    if (_checking) return;
    _checking = true;
    try {
      final config = Get.find<AppConfigController>();
      await config.refresh();
      final result = await AppUpdateChecker.evaluate(
        config.currentVersion.value,
      );
      if (!result.isForced && mounted) Get.offAllNamed(AppRoutes.splash);
    } finally {
      _checking = false;
    }
  }

  void _update() {
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(
        AppAnalyticsController.to.logTap('app_update_required_confirm'),
      );
    }
    unawaited(AppStoreLauncher.openStoreListing());
  }

  @override
  Widget build(BuildContext context) {
    final target = _result?.versionName;
    final installed = _result?.installedVersion;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && Platform.isAndroid) SystemNavigator.pop();
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AppBackdropImage(AppAssets.signInBackground),
            ColoredBox(color: AppColors.black.withValues(alpha: 0.55)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        AppAssets.appIc,
                        width: 76,
                        height: 76,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Time for an update',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading32Bold().copyWith(
                        fontSize: 26,
                        height: 1.15,
                        color: AppColors.textCream,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      target == null
                          ? 'This version is no longer supported. Update to '
                                'keep using the app. Your collection is safe.'
                          : 'This version is no longer supported. Update to '
                                '$target to keep using the app. Your '
                                'collection is safe.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body16().copyWith(
                        fontSize: 15,
                        height: 1.4,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(flex: 4),
                    CommonPrimaryButton(
                      label: 'Update now',
                      onPressed: _update,
                    ),
                    if (installed != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'You have $installed',
                        style: AppTextStyles.bodyS().copyWith(
                          fontSize: 12,
                          color: AppColors.textWolf,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
