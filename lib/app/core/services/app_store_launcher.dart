import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

abstract final class AppStoreLauncher {
  AppStoreLauncher._();

  static Future<void> openStoreListing() async {
    final info = await PackageInfo.fromPlatform();

    if (Platform.isAndroid) {
      final marketUri = Uri.parse('market://details?id=${info.packageName}');
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(
        Uri.parse(
          'https://play.google.com/store/apps/details?id=${info.packageName}',
        ),
        mode: LaunchMode.externalApplication,
      );
      return;
    }

    if (Platform.isIOS) {
      final storeId = AppConstants.iosAppStoreId.trim();
      if (storeId.isNotEmpty) {
        await launchUrl(
          Uri.parse('https://apps.apple.com/app/id$storeId'),
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }

  static Future<void> openAppleSubscriptions() async {
    await launchUrl(
      Uri.parse(AppConstants.appleSubscriptionsUrl),
      mode: LaunchMode.externalApplication,
    );
  }
}
