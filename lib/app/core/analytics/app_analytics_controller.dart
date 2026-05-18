import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'analytics_screens.dart';
import '../../modules/navigation/bottom_nav_controller.dart';

/// Central Firebase Analytics: `{screen}_view` and `{button}_click` events.
class AppAnalyticsController extends GetxController {
  AppAnalyticsController() : _analytics = FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  static AppAnalyticsController get to => Get.find<AppAnalyticsController>();

  /// Lowercase [a-z0-9_], max length so suffix `_view` / `_click` fits in 40 chars.
  static String sanitizeKey(String raw) {
    var s = raw.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
    s = s.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    if (s.isEmpty) return 'item';
    if (!RegExp(r'^[a-z]').hasMatch(s)) {
      s = 'k_$s';
    }
    const maxBase = 32;
    if (s.length > maxBase) {
      s = s.substring(0, maxBase).replaceAll(RegExp(r'_$'), '');
    }
    return s;
  }

  /// Logs custom event `{screenKey}_view` with `screen_name` parameter.
  Future<void> logScreenView(String screenKey) async {
    final base = sanitizeKey(screenKey);
    final name = '${base}_view';
    await _safeLog(name, {'screen_name': screenKey});
  }

  /// Logs custom event `{buttonKey}_click` with `button_name` and optional params.
  Future<void> logTap(
    String buttonKey, [
    Map<String, Object>? extra,
  ]) async {
    final base = sanitizeKey(buttonKey);
    final name = '${base}_click';
    final params = <String, Object>{'button_name': buttonKey};
    if (extra != null) {
      params.addAll(extra);
    }
    await _safeLog(name, params);
  }

  /// When route is shell, log the active tab screen (not generic "shell").
  Future<void> logShellCurrentTab() async {
    if (!Get.isRegistered<BottomNavController>()) {
      await logScreenView(AnalyticsScreens.shellTabScreenName(0));
      return;
    }
    final idx = Get.find<BottomNavController>().index.value;
    await logScreenView(AnalyticsScreens.shellTabScreenName(idx));
  }

  Future<void> _safeLog(String name, Map<String, Object> params) async {
    if (kDebugMode) {
      debugPrint('[FirebaseAnalytics] → $name  $params');
    }
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (e, st) {
      debugPrint('[AppAnalytics] logEvent failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }
}
