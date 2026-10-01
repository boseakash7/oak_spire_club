import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../platform/app_platform.dart';
import '../theme/app_colors.dart';
import 'app_motion.dart';

/// The route transition for every screen, chosen per platform:
///
/// * iOS — the native Cupertino push: the new page slides in from the right,
///   the old one parallaxes left, and the edge swipe-back tracks the finger.
/// * Android — Material's shared-axis Z transition: the new page scales and
///   fades up while the old one recedes.
/// * Reduce motion — a plain cross-fade.
///
/// GetX only keeps its iOS back-swipe detector for a route's *own*
/// `customTransition`, not the app-wide one, so [AppPages] attaches this to
/// every `GetPage` rather than [GetMaterialApp.customTransition].
class AppPageTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) {
      return FadeTransition(opacity: animation, child: child);
    }

    if (AppPlatform.isCupertino) {
      final route = ModalRoute.of(context);
      return CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        // Follow the finger 1:1 while a back swipe is in progress.
        linearTransition: route is GetPageRoute && route.popGestureInProgress,
        child: child,
      );
    }

    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.scaled,
      fillColor: AppColors.black,
      child: child,
    );
  }
}
