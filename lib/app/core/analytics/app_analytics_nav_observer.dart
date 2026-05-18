import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import 'analytics_screens.dart';
import 'app_analytics_controller.dart';

/// Maps pushed routes to stable screen keys and forwards to [AppAnalyticsController].
class AppAnalyticsNavObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _logRoute(newRoute);
    }
  }

  void _logRoute(Route<dynamic> route) {
    if (!Get.isRegistered<AppAnalyticsController>()) return;
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;

    final analytics = AppAnalyticsController.to;
    if (name == AppRoutes.shell) {
      unawaited(analytics.logShellCurrentTab());
      return;
    }
    final key = AnalyticsScreens.screenKeyForRoute(name);
    unawaited(analytics.logScreenView(key));
  }
}
