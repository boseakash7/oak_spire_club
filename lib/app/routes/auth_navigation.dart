import 'package:get/get.dart';

import '../core/storage/app_storage.dart';
import '../data/models/user_model.dart';
import 'app_routes.dart';

/// Routes after login, signup, or splash when a session already exists.
class AuthNavigation {
  const AuthNavigation._();

  static const postAuthSubscriptionArg = 'postAuth';

  static void openWelcome() {
    Get.offAllNamed(AppRoutes.getStarted);
  }

  static void completeSession(UserModel user) {
    if (user.needsSubscriptionOffer &&
        !AppStorage.hasDismissedSubscriptionOfferFor(user.id)) {
      Get.offAllNamed(
        AppRoutes.subscription,
        arguments: const {postAuthSubscriptionArg: true},
      );
    } else {
      Get.offAllNamed(AppRoutes.shell);
    }
  }
}
