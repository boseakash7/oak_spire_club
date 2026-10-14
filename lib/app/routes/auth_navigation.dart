import 'package:get/get.dart';

import '../data/models/user_model.dart';
import 'app_routes.dart';

/// Routes after login, signup, or splash when a session already exists.
class AuthNavigation {
  const AuthNavigation._();

  static const postAuthSubscriptionArg = 'postAuth';

  static void openWelcome() {
    Get.offAllNamed(AppRoutes.getStarted);
  }

  /// After login/register: require OTP when email is not verified.
  static void afterAuth(UserModel user) {
    if (!user.emailVerified) {
      Get.toNamed(
        AppRoutes.verifyOtp,
        arguments: {
          'email': user.email ?? '',
        },
      );
      return;
    }
    completeSession(user);
  }

  /// Every signed-in user lands on Home. The subscription screen is offered
  /// from Home's Premium card, Settings and a `LIMIT_EXCEEDED` response,
  /// not after sign-in.
  static void completeSession(UserModel user) {
    Get.offAllNamed(AppRoutes.shell);
  }
}
