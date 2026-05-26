import 'package:get/get.dart';

import '../data/models/subscription_payment_receipt.dart';
import 'app_routes.dart';
import 'auth_navigation.dart';

abstract final class SubscriptionPaymentSuccessNavigation {
  static const String messageArg = 'message';
  static const String postAuthArg = 'postAuth';
  static const String receiptArg = 'receipt';
  static const String paymentSucceededArg = 'paymentSucceeded';

  static void open({
    required String message,
    required bool isPostAuth,
    required SubscriptionPaymentReceipt receipt,
    required bool paymentSucceeded,
  }) {
    Get.offNamed(
      AppRoutes.subscriptionPaymentSuccess,
      arguments: {
        messageArg: message,
        postAuthArg: isPostAuth,
        receiptArg: receipt.toArguments(),
        paymentSucceededArg: paymentSucceeded,
      },
    );
  }

  static String messageFromArguments() {
    final args = Get.arguments;
    if (args is Map && args[messageArg] != null) {
      return args[messageArg].toString();
    }
    return 'Your subscription is now active.';
  }

  static SubscriptionPaymentReceipt? receiptFromArguments() {
    final args = Get.arguments;
    if (args is! Map) return null;
    final raw = args[receiptArg];
    if (raw is! Map) return null;
    return SubscriptionPaymentReceipt.fromArguments(
      Map<dynamic, dynamic>.from(raw),
    );
  }

  static bool isPostAuthFromArguments() {
    final args = Get.arguments;
    return args is Map && args[postAuthArg] == true;
  }

  static bool isPaymentSuccessful() {
    final args = Get.arguments;
    if (args is Map && args.containsKey(paymentSucceededArg)) {
      return args[paymentSucceededArg] == true;
    }
    final receipt = receiptFromArguments();
    return receipt?.isPaid ?? true;
  }

  static void continueAfterPayment() {
    if (isPaymentSuccessful()) {
      continueToApp();
      return;
    }

    final postAuth = isPostAuthFromArguments();
    Get.offNamed(
      AppRoutes.subscription,
      arguments: postAuth
          ? {AuthNavigation.postAuthSubscriptionArg: true}
          : null,
    );
  }

  static void continueToApp() {
    if (isPostAuthFromArguments()) {
      Get.offAllNamed(AppRoutes.shell);
    } else {
      Get.until((route) => route.settings.name == AppRoutes.shell);
      if (Get.currentRoute != AppRoutes.shell) {
        Get.offAllNamed(AppRoutes.shell);
      }
    }
  }
}
