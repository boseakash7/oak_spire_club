import 'package:get/get.dart';

import 'app_routes.dart';

/// Opens IAP / subscription when the API returns `LIMIT_EXCEEDED`.
abstract final class SubscriptionLimitNavigation {
  static const String limitMessageArg = 'limitMessage';

  static void open(String message) {
    final trimmed = message.trim();
    final display = trimmed.isNotEmpty
        ? trimmed
        : 'You have reached your free collection limit.';
    final args = {limitMessageArg: display};

    if (Get.currentRoute == AppRoutes.subscription) {
      Get.offNamed(AppRoutes.subscription, arguments: args);
    } else {
      Get.toNamed(AppRoutes.subscription, arguments: args);
    }
  }

  static String? messageFromArguments() {
    final args = Get.arguments;
    if (args is Map && args[limitMessageArg] != null) {
      return args[limitMessageArg].toString();
    }
    return null;
  }
}
