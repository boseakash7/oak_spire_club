import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import '../../data/models/app_current_version_model.dart';

enum AppUpdateKind { none, optional, forced }

class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.kind,
    this.versionName,
    this.installedVersion,
    this.notes = const [],
  });

  const AppUpdateCheckResult.upToDate()
    : kind = AppUpdateKind.none,
      versionName = null,
      installedVersion = null,
      notes = const [];

  final AppUpdateKind kind;

  /// The store's version ("1.8.0"), when the server names it.
  final String? versionName;

  /// This install's version ("1.6.2").
  final String? installedVersion;
  final List<String> notes;

  bool get needsUpdate => kind != AppUpdateKind.none;
  bool get isForced => kind == AppUpdateKind.forced;
}

abstract final class AppUpdateChecker {
  AppUpdateChecker._();

  /// Compares this install's build number against the server's rule: below
  /// the minimum is forced, below the latest is optional.
  static Future<AppUpdateCheckResult> evaluate(
    AppCurrentVersion? remote,
  ) async {
    if (remote == null) return const AppUpdateCheckResult.upToDate();

    final android = Platform.isAndroid;
    final latest = android ? remote.androidLatest : remote.iosLatest;
    final min = android ? remote.androidMin : remote.iosMin;
    if (latest == null && min == null) {
      return const AppUpdateCheckResult.upToDate();
    }

    final info = await PackageInfo.fromPlatform();
    final local = int.tryParse(info.buildNumber) ?? 0;

    final AppUpdateKind kind;
    if (min != null && local < min) {
      kind = AppUpdateKind.forced;
    } else if (latest != null && local < latest) {
      kind = AppUpdateKind.optional;
    } else {
      return const AppUpdateCheckResult.upToDate();
    }

    return AppUpdateCheckResult(
      kind: kind,
      versionName: remote.versionName,
      installedVersion: info.version,
      notes: remote.notes,
    );
  }
}
