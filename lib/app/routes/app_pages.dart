import 'package:get/get.dart';

import '../modules/get_started/get_started_view.dart';
import '../modules/auth/forgot_password/forgot_password_binding.dart';
import '../modules/auth/forgot_password/forgot_password_view.dart';
import '../modules/auth/sign_in/sign_in_binding.dart';
import '../modules/auth/sign_in/sign_in_view.dart';
import '../modules/auth/sign_up/sign_up_binding.dart';
import '../modules/auth/sign_up/sign_up_view.dart';
import '../modules/auth/verify_otp/verify_otp_binding.dart';
import '../modules/auth/verify_otp/verify_otp_view.dart';
import '../modules/add_collection/add_collection_binding.dart';
import '../modules/add_collection/add_collection_view.dart';
import '../modules/navigation/bottom_nav_binding.dart';
import '../modules/navigation/bottom_nav_shell.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';
import '../modules/taste/taste_binding.dart';
import '../modules/taste/taste_view.dart';
import '../modules/market/benchmark_detail_binding.dart';
import '../modules/market/benchmark_detail_view.dart';
import '../modules/subscription/subscription_binding.dart';
import '../modules/subscription/subscription_payment_success_view.dart';
import '../modules/subscription/subscription_skip_view.dart';
import '../modules/subscription/subscription_view.dart';
import '../modules/settings/account/account_binding.dart';
import '../modules/settings/account/account_view.dart';
import '../modules/settings/notifications/notifications_binding.dart';
import '../modules/settings/notifications/notifications_view.dart';
import '../modules/settings/delete_account/delete_account_binding.dart';
import '../modules/settings/delete_account/delete_account_view.dart';
import '../modules/settings/privacy/privacy_binding.dart';
import '../modules/settings/privacy/privacy_view.dart';
import '../modules/settings/help/help_support_view.dart';
import '../modules/settings/about/about_view.dart';
import '../modules/settings/legal/legal_web_view.dart';
import 'app_routes.dart';

class AppPages {
  const AppPages._();

  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.shell,
      page: () => const BottomNavShell(),
      binding: BottomNavBinding(),
    ),
    GetPage(
      name: AppRoutes.getStarted,
      page: () => const GetStartedView(),
    ),
    GetPage(
      name: AppRoutes.signIn,
      page: () => const SignInView(),
      binding: SignInBinding(),
    ),
    GetPage(
      name: AppRoutes.signUp,
      page: () => const SignUpView(),
      binding: SignUpBinding(),
    ),
    GetPage(
      name: AppRoutes.verifyOtp,
      page: () => const VerifyOtpView(),
      binding: VerifyOtpBinding(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: AppRoutes.addToCollection,
      page: () => const AddCollectionView(),
      binding: AddCollectionBinding(),
    ),
    GetPage(
      name: AppRoutes.tasteBottles,
      page: () => const TasteView(),
      binding: TasteBinding(),
    ),
    GetPage(
      name: AppRoutes.benchmarkDetail,
      page: () => const BenchmarkDetailView(),
      binding: BenchmarkDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.subscription,
      page: () => const SubscriptionView(),
      binding: SubscriptionBinding(),
    ),
    GetPage(
      name: AppRoutes.subscriptionSkip,
      page: () => const SubscriptionSkipView(),
    ),
    GetPage(
      name: AppRoutes.subscriptionPaymentSuccess,
      page: () => const SubscriptionPaymentSuccessView(),
    ),
    GetPage(
      name: AppRoutes.settingsAccount,
      page: () => const AccountView(),
      binding: AccountBinding(),
    ),
    GetPage(
      name: AppRoutes.settingsNotifications,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
    ),
    GetPage(
      name: AppRoutes.settingsPrivacy,
      page: () => const PrivacyView(),
      binding: PrivacyBinding(),
    ),
    GetPage(
      name: AppRoutes.settingsDeleteAccount,
      page: () => const DeleteAccountView(),
      binding: DeleteAccountBinding(),
    ),
    GetPage(
      name: AppRoutes.settingsHelp,
      page: () => const HelpSupportView(),
    ),
    GetPage(
      name: AppRoutes.settingsAbout,
      page: () => const AboutView(),
    ),
    GetPage(
      name: AppRoutes.settingsLegalWeb,
      page: () => const LegalWebView(),
    ),
  ];
}
