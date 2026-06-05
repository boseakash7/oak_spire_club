import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import '../../data/models/app_current_version_model.dart';

class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.needsUpdate,
    this.isForced = false,
  });

  const AppUpdateCheckResult.upToDate()
      : needsUpdate = false,
        isForced = false;

  final bool needsUpdate;
  final bool isForced;
}

abstract final class AppUpdateChecker {
  AppUpdateChecker._();

  static Future<AppUpdateCheckResult> evaluate(
    AppCurrentVersion? remote,
  ) async {
    if (remote == null) return const AppUpdateCheckResult.upToDate();

    final remoteBuild = Platform.isAndroid ? remote.android : remote.ios;
    if (remoteBuild == null) return const AppUpdateCheckResult.upToDate();

    final info = await PackageInfo.fromPlatform();
    final localBuild = int.tryParse(info.buildNumber) ?? 0;
    if (localBuild >= remoteBuild) {
      return const AppUpdateCheckResult.upToDate();
    }

    return AppUpdateCheckResult(
      needsUpdate: true,
      isForced: remote.isForced,
    );
  }
}
