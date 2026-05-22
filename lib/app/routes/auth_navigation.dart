import 'package:get/get.dart';

import '../data/models/user_model.dart';
import 'app_routes.dart';

/// Routes after login, signup, or splash when a session already exists.
class AuthNavigation {
  const AuthNavigation._();

  static const postAuthSubscriptionArg = 'postAuth';

  static void completeSession(UserModel user) {
    if (user.needsSubscriptionOffer) {
      Get.offAllNamed(
        AppRoutes.subscription,
        arguments: const {postAuthSubscriptionArg: true},
      );
    } else {
      Get.offAllNamed(AppRoutes.shell);
    }
  }
}
