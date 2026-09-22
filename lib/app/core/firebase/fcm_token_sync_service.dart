import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/repositories/user_token_repository.dart';
import '../storage/app_storage.dart';

/// Keeps the backend FCM token in sync after login and on every app launch.
abstract final class FcmTokenSyncService {
  FcmTokenSyncService._();

  static bool _started = false;

  /// Registers [onTokenRefresh] listener. Safe to call once at app start.
  static void start() {
    if (kIsWeb || _started) return;
    _started = true;

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) => unawaited(sync(fcmToken: token)),
      onError: (Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('[FCM] Token refresh listener error: $e\n$st');
        }
      },
    );
  }

  /// Uploads the current device token when a session exists.
  static Future<void> syncIfLoggedIn() async {
    await AppStorage.ensureReady();
    final userId = AppStorage.userId;
    if (userId == null || userId.isEmpty) return;
    await sync(userId: userId);
  }

  /// Resolves token (if needed) and posts to [UserTokenRepository.saveUserFcm].
  static Future<void> sync({String? userId, String? fcmToken}) async {
    if (kIsWeb) return;

    try {
      await AppStorage.ensureReady();

      final resolvedUserId = userId ?? AppStorage.userId;
      if (resolvedUserId == null || resolvedUserId.isEmpty) return;

      final resolvedToken = fcmToken ?? await _resolveFcmToken();
      if (resolvedToken == null || resolvedToken.isEmpty) return;

      if (!Get.isRegistered<UserTokenRepository>()) return;

      await Get.find<UserTokenRepository>().saveUserFcm(
        userId: resolvedUserId,
        fcmToken: resolvedToken,
      );

      if (kDebugMode) {
        debugPrint('[FCM] Token synced for user_id=$resolvedUserId');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FCM] Token sync failed: $e\n$st');
      }
    }
  }

  static Future<String?> _resolveFcmToken() async {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission();
    }

    return FirebaseMessaging.instance.getToken();
  }

  /// Removes the device token from the backend on logout. [fcmToken] is optional.
  static Future<void> clearOnLogout() async {
    if (kIsWeb) return;

    try {
      await AppStorage.ensureReady();

      final userId = AppStorage.userId;
      if (userId == null || userId.isEmpty) return;

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (_) {}

      if (!Get.isRegistered<UserTokenRepository>()) return;

      await Get.find<UserTokenRepository>().deleteUserFcm(
        userId: userId,
        fcmToken: fcmToken,
      );

      if (kDebugMode) {
        debugPrint('[FCM] Token removed for user_id=$userId');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FCM] Token removal failed: $e\n$st');
      }
    }
  }
}
