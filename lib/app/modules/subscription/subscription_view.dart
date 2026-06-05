import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/animations/app_motion.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/payment_currency.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/limit_exceeded_exception.dart';
import '../../core/services/app_store_launcher.dart';
import '../../core/services/apple_in_app_purchase_service.dart';
import '../../core/storage/app_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_subscription_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/widgets/animated_pressable.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_confirm_dialog.dart';
import '../../core/widgets/common_primary_button.dart';
import '../../core/widgets/gradient_text.dart';
import '../../data/models/package_transaction_model.dart';
import '../../data/models/razorpay_payment_create_model.dart';
import '../../data/models/subscription_package_model.dart';
import '../../data/models/subscription_payment_receipt.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/package_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../routes/app_routes.dart';
import '../../routes/auth_navigation.dart';
import '../../routes/subscription_limit_navigation.dart';
import '../../routes/subscription_payment_success_navigation.dart';
import '../session/app_config_controller.dart';
import '../session/user_session_controller.dart';
import 'subscription_controller.dart';
import 'subscription_loading_view.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  Razorpay? _razorpay;
  AppleInAppPurchaseService? _iapService;
  Worker? _iapPackagesWorker;
  late final SubscriptionController _subscription;

  var _isCreatingPayment = false;
  var _isVerifyingPayment = false;
  var _isLoadingApplePrices = false;
  RazorpayPaymentCreateModel? _pendingPayment;
  final _appleLocalizedPrices = <String, String>{};

  bool get _isIosCheckout => Platform.isIOS;

  bool get _isPostAuth {
    final args = Get.arguments;
    return args is Map && args[AuthNavigation.postAuthSubscriptionArg] == true;
  }

  void _openSkipConfirmation() {
    Get.toNamed(
      AppRoutes.subscriptionSkip,
      arguments: _isPostAuth
          ? {AuthNavigation.postAuthSubscriptionArg: true}
          : null,
    );
  }

  @override
  void initState() {
    super.initState();
    _subscription = Get.find<SubscriptionController>();
    if (_isIosCheckout) {
      _iapService = AppleInAppPurchaseService(
        onPurchaseUpdated: _onApplePurchaseUpdated,
      );
      _iapService!.startListening();
      _iapPackagesWorker = ever<bool>(_subscription.isLoadingPackages, (
        loading,
      ) {
        if (!loading) unawaited(_loadAppleProducts());
      });
      if (!_subscription.isLoadingPackages.value) {
        unawaited(_loadAppleProducts());
      }
    } else {
      _razorpay = Razorpay();
      _razorpay!
        ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
        ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError)
        ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    }
  }

  @override
  void dispose() {
    _iapPackagesWorker?.dispose();
    _iapService?.dispose();
    _razorpay?.clear();
    super.dispose();
  }

  Future<void> _loadAppleProducts() async {
    final service = _iapService;
    if (service == null) return;
    final productIds = _subscription.packages
        .map((plan) => plan.appleProductId)
        .toSet();
    if (!mounted) return;
    setState(() => _isLoadingApplePrices = true);
    try {
      await service.loadProducts(productIds);
      if (!mounted) return;
      setState(() {
        _appleLocalizedPrices
          ..clear()
          ..addAll({for (final p in service.products) p.id: p.price});
      });
    } finally {
      if (mounted) setState(() => _isLoadingApplePrices = false);
    }
  }

  String? _applePriceForPlan(SubscriptionPackageModel plan) =>
      _appleLocalizedPrices[plan.appleProductId];

  void _onApplePurchaseUpdated(PurchaseDetails purchase) {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        break;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        unawaited(_submitAppleSubscribe(purchase));
      case PurchaseStatus.error:
        if (mounted) setState(() => _isVerifyingPayment = false);
        final message = purchase.error?.message.trim();
        unawaited(
          AppSnackbar.error(
            message != null && message.isNotEmpty
                ? message
                : 'Purchase failed. Please try again.',
          ),
        );
      case PurchaseStatus.canceled:
        if (mounted) setState(() => _isVerifyingPayment = false);
    }
  }

  Future<void> _submitAppleSubscribe(PurchaseDetails purchase) async {
    final plan = _subscription.selectedPackage;
    final userId = AppStorage.userId?.trim();
    final purchaseId = purchase.purchaseID?.trim() ?? '';

    if (plan == null || userId == null || userId.isEmpty) {
      await AppSnackbar.error(
        'Could not confirm subscription. Please try again.',
      );
      return;
    }
    if (purchaseId.isEmpty) {
      await AppSnackbar.error('Missing purchase id from App Store.');
      return;
    }

    if (!mounted) return;
    setState(() => _isVerifyingPayment = true);
    try {
      final message = await Get.find<PackageRepository>().subscribeApple(
        userId: userId,
        packageId: plan.id,
        uniqueId: purchaseId,
      );
      await Get.find<UserRepository>().refreshUserById(userId);
      await _subscription.reload();

      if (!mounted) return;
      SubscriptionPaymentSuccessNavigation.open(
        message: message,
        isPostAuth: _isPostAuth,
        paymentSucceeded: true,
        receipt: SubscriptionPaymentReceipt(
          merchantName: AppConstants.appName,
          planTitle: plan.displayTitle,
          amount: double.tryParse(plan.price) ?? 0,
          currency: PaymentCurrency.usd,
          status: 'paid',
          paidAt: DateTime.now(),
          localOrderId: plan.id,
          razorpayOrderId: purchase.productID,
          razorpayPaymentId: purchaseId,
        ),
      );
    } on LimitExceededException {
      // IAP opened by shared API handler.
    } on ApiException catch (e) {
      await AppSnackbar.error(e.message);
    } catch (e) {
      await AppSnackbar.error(e.toString());
    } finally {
      if (mounted) setState(() => _isVerifyingPayment = false);
    }
  }

  Future<void> _startAppleCheckout(SubscriptionPackageModel plan) async {
    final service = _iapService;
    if (service == null) return;

    if (!service.isAvailable) {
      await AppSnackbar.error('In-app purchases are not available.');
      return;
    }

    final product = service.productForAppleId(plan.appleProductId);
    if (product == null) {
      await _loadAppleProducts();
      final retryProduct = service.productForAppleId(plan.appleProductId);
      if (retryProduct == null) {
        await AppSnackbar.error(
          'This plan is not available on the App Store yet.',
        );
        return;
      }
      await _purchaseAppleProduct(retryProduct);
      return;
    }

    await _purchaseAppleProduct(product);
  }

  Future<void> _purchaseAppleProduct(ProductDetails product) async {
    final service = _iapService;
    if (service == null) return;

    setState(() => _isCreatingPayment = true);
    try {
      final started = await service.purchase(product);
      if (!started) {
        await AppSnackbar.error('Could not open App Store purchase.');
      }
    } catch (e) {
      await AppSnackbar.error(e.toString());
    } finally {
      if (mounted) setState(() => _isCreatingPayment = false);
    }
  }

  Future<void> _restoreApplePurchases() async {
    final service = _iapService;
    if (service == null || !service.isAvailable) {
      await AppSnackbar.error('Restore is not available right now.');
      return;
    }

    setState(() => _isVerifyingPayment = true);
    try {
      await service.restorePurchases();
      await AppSnackbar.info('Checking for previous purchases…');
    } catch (e) {
      await AppSnackbar.error(e.toString());
    } finally {
      Future<void>.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _isVerifyingPayment = false);
      });
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse res) {
    unawaited(
      _submitPaymentVerify(
        status: 'paid',
        razorpayPaymentId: res.paymentId?.trim() ?? '',
        razorpayOrderId: res.orderId?.trim(),
        appMessage: 'Payment completed from app',
      ),
    );
  }

  void _onPaymentError(PaymentFailureResponse res) {
    unawaited(
      _submitPaymentVerify(
        status: 'failed',
        razorpayPaymentId: '',
        appMessage: res.message?.trim().isNotEmpty == true
            ? res.message!.trim()
            : 'Purchase failed from app',
      ),
    );
  }

  Future<void> _submitPaymentVerify({
    required String status,
    required String razorpayPaymentId,
    String? razorpayOrderId,
    required String appMessage,
  }) async {
    final pending = _pendingPayment;
    if (pending == null) {
      await AppSnackbar.error('Payment session expired. Please try again.');
      return;
    }

    final isPaid = status == 'paid';
    if (isPaid && razorpayPaymentId.isEmpty) {
      await AppSnackbar.error(
        'Could not confirm payment. Please contact support if you were charged.',
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isVerifyingPayment = true);
    try {
      final verified = await Get.find<PackageRepository>().verifyPayment(
        localOrderId: pending.localOrderId,
        status: status,
        razorpayOrderId: razorpayOrderId ?? pending.razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpayPlanId: pending.razorpayPlanId,
        message: appMessage,
      );
      _pendingPayment = null;
      if (!mounted) return;

      final defaultMessage = isPaid
          ? 'Your subscription is now active.'
          : 'Your purchase could not be completed.';
      final displayMessage = verified.message.trim().isNotEmpty
          ? verified.message.trim()
          : defaultMessage;

      final plan = _subscription.selectedPackage;
      SubscriptionPaymentSuccessNavigation.open(
        message: displayMessage,
        isPostAuth: _isPostAuth,
        paymentSucceeded: isPaid,
        receipt: SubscriptionPaymentReceipt(
          merchantName: AppConstants.appName,
          planTitle: plan?.displayTitle ?? pending.planType,
          amount: pending.amount,
          currency: pending.currency,
          status: verified.status,
          paidAt: DateTime.now(),
          localOrderId: verified.localOrderId,
          razorpayOrderId: verified.razorpayOrderId.trim().isNotEmpty
              ? verified.razorpayOrderId
              : pending.razorpayOrderId,
          razorpayPaymentId: verified.razorpayPaymentId,
        ),
      );
    } on LimitExceededException {
      // IAP opened by shared API handler.
    } on ApiException catch (e) {
      await AppSnackbar.error(e.message);
    } catch (e) {
      await AppSnackbar.error(e.toString());
    } finally {
      if (mounted) setState(() => _isVerifyingPayment = false);
    }
  }

  void _onExternalWallet(ExternalWalletResponse res) {
    unawaited(
      AppSnackbar.info('External wallet: ${res.walletName ?? 'unknown'}'),
    );
  }

  Future<void> _confirmCancelSubscription() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Cancel subscription?',
      message:
          'Your premium access will end after cancellation. You can subscribe again anytime.',
      confirmLabel: 'Cancel subscription',
      cancelLabel: 'Keep subscription',
      confirmIsDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    await _subscription.cancelSubscription();
  }

  Future<void> _startCheckout() async {
    if (_isCreatingPayment || _isVerifyingPayment) return;

    final plan = _subscription.selectedPackage;
    if (plan == null) {
      await AppSnackbar.error('Select a plan first.');
      return;
    }

    final userId = AppStorage.userId?.trim();
    if (userId == null || userId.isEmpty) {
      await AppSnackbar.error('Please sign in again.');
      return;
    }

    if (_isIosCheckout) {
      await _startAppleCheckout(plan);
      return;
    }

    setState(() => _isCreatingPayment = true);
    try {
      final payment = await Get.find<PackageRepository>().createPayment(
        userId: userId,
        planType: plan.planTypeForPayment,
        amount: plan.price,
        packageId: plan.id,
        currency: PaymentCurrency.usd,
      );

      if (!payment.hasValidOrder) {
        await AppSnackbar.error(
          payment.message.isNotEmpty
              ? payment.message
              : 'Could not start payment. Please try again.',
        );
        return;
      }

      var key = payment.keyId.trim();
      if (key.isEmpty) {
        key = AppStorage.razorpayKeyId?.trim() ?? '';
      }
      if (key.isEmpty && Get.isRegistered<AppConfigController>()) {
        await Get.find<AppConfigController>().refresh();
        key = AppStorage.razorpayKeyId?.trim() ?? '';
      }
      if (key.isEmpty) {
        await AppSnackbar.error(
          'Payment is not available right now. Please try again later.',
        );
        return;
      }

      _pendingPayment = payment;

      final options = <String, Object?>{
        'key': key,
        'order_id': payment.razorpayOrderId,
        'amount': payment.razorpayAmount,
        'currency': payment.currency,
        'name': AppConstants.appName,
        'description': '${plan.displayTitle} subscription',
        'prefill': <String, Object?>{'contact': '', 'email': ''},
        'theme': <String, Object?>{'color': '#B9861F'},
      };

      _razorpay!.open(options);
    } on LimitExceededException {
      // IAP opened by shared API handler.
    } on ApiException catch (e) {
      await AppSnackbar.error(e.message);
    } catch (e) {
      await AppSnackbar.error(e.toString());
    } finally {
      if (mounted) setState(() => _isCreatingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final limitMessage = SubscriptionLimitNavigation.messageFromArguments();

    return PopScope(
      canPop: !_isPostAuth && !_isVerifyingPayment,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppAssets.subscriptionBackground,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Image.asset(AppAssets.signUpBackground, fit: BoxFit.cover),
            ),
            SafeArea(
              child: Obx(() {
                if (_subscription.isBootstrapping.value) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSubscriptionTheme.horizontalPadding - 10,
                          4,
                          AppSubscriptionTheme.horizontalPadding,
                          0,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AppBackButton(
                            color: AppColors.textCream,
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                                return;
                              }
                              Get.back<void>();
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSubscriptionTheme.horizontalPadding,
                            8,
                            AppSubscriptionTheme.horizontalPadding,
                            24,
                          ),
                          child: const SubscriptionLoadingView(),
                        ),
                      ),
                    ],
                  );
                }

                final showCheckout = _subscription.showCheckout;
                final showFree = _subscription.showFreeUser;
                final showActive = _subscription.showActiveSubscription;

                final showManagedSubscription = showActive || showFree;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showManagedSubscription) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSubscriptionTheme.horizontalPadding - 10,
                          4,
                          AppSubscriptionTheme.horizontalPadding,
                          0,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AppBackButton(
                            color: AppColors.textCream,
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                                return;
                              }
                              Get.back<void>();
                            },
                          ),
                        ),
                      ),
                    ],
                    if (limitMessage != null &&
                        limitMessage.isNotEmpty &&
                        showCheckout) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSubscriptionTheme.horizontalPadding,
                          12,
                          AppSubscriptionTheme.horizontalPadding,
                          0,
                        ),
                        child: _SubscriptionLimitBanner(message: limitMessage),
                      ),
                    ],
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          AppSubscriptionTheme.horizontalPadding,
                          showManagedSubscription
                              ? 8
                              : limitMessage != null &&
                                    limitMessage.isNotEmpty &&
                                    showCheckout
                              ? AppSubscriptionTheme.scrollTopPaddingWithBanner
                              : AppSubscriptionTheme.scrollTopPaddingDefault,
                          AppSubscriptionTheme.horizontalPadding,
                          24,
                        ),
                        child: showFree
                            ? const _FreeUserSubscriptionBody()
                            : showActive
                            ? _ActiveSubscriptionBody(
                                subscription: _subscription,
                                onCancel: _confirmCancelSubscription,
                                onManageApple: () => unawaited(
                                  AppStoreLauncher.openAppleSubscriptions(),
                                ),
                              )
                            : _CheckoutSubscriptionBody(
                                subscription: _subscription,
                                useAppleStorePrices: _isIosCheckout,
                                applePriceForPlan: _applePriceForPlan,
                                isLoadingApplePrices: _isLoadingApplePrices,
                              ),
                      ),
                    ),
                    if (showCheckout && !_subscription.isBootstrapping.value) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSubscriptionTheme.horizontalPadding,
                          0,
                          AppSubscriptionTheme.horizontalPadding,
                          12,
                        ),
                        child: CommonPrimaryButton(
                          label: 'Start free - 7 days trial',
                          isLoading: _isCreatingPayment || _isVerifyingPayment,
                          onPressed: _startCheckout,
                        ),
                      ),
                      if (_isIosCheckout)
                        Center(
                          child: GestureDetector(
                            onTap: _isVerifyingPayment
                                ? null
                                : () => unawaited(_restoreApplePurchases()),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Restore purchases',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.subscriptionSkipLink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: _openSkipConfirmation,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: AppColors.subscriptionSkipLink
                                    .withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Skip this for now',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.subscriptionSkipLink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ),
            if (_isVerifyingPayment)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gold1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatTransactionDate(int unixSeconds) {
  if (unixSeconds <= 0) return '—';
  final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
  return DateFormat('MMM d, yyyy').format(dt);
}

class _CheckoutSubscriptionBody extends StatelessWidget {
  const _CheckoutSubscriptionBody({
    required this.subscription,
    required this.useAppleStorePrices,
    required this.applePriceForPlan,
    required this.isLoadingApplePrices,
  });

  final SubscriptionController subscription;
  final bool useAppleStorePrices;
  final String? Function(SubscriptionPackageModel plan) applePriceForPlan;
  final bool isLoadingApplePrices;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FadeSlideEntrance(index: 0, child: _SubscriptionHeader()),
        const SizedBox(height: 34),
        const FadeSlideEntrance(
          index: 1,
          child: _BenefitRow(
            spans: [
              TextSpan(text: 'Track '),
              TextSpan(
                text: 'unlimited',
                style: TextStyle(color: AppColors.subscriptionBenefitGold),
              ),
              TextSpan(text: ' collection value overtime.'),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const FadeSlideEntrance(
          index: 2,
          child: _BenefitRow(
            spans: [
              TextSpan(text: 'Access to the '),
              TextSpan(
                text: '10000+ bottles ',
                style: TextStyle(color: AppColors.subscriptionBenefitGold),
              ),
              TextSpan(text: 'database.'),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const FadeSlideEntrance(
          index: 3,
          child: _BenefitRow(
            spans: [
              TextSpan(
                text: 'Full access',
                style: TextStyle(color: AppColors.subscriptionBenefitGoldAlt),
              ),
              TextSpan(text: ' to bottle insights and tasting.'),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const FadeSlideEntrance(
          index: 4,
          child: _BenefitRow(
            spans: [
              TextSpan(
                text: 'No',
                style: TextStyle(
                  color: AppColors.subscriptionBenefitLimitsPrimary,
                ),
              ),
              TextSpan(text: ' daily '),
              TextSpan(
                text: 'limits',
                style: TextStyle(
                  color: AppColors.subscriptionBenefitLimitsSecondary,
                ),
              ),
              TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 36),
        _PackagePlanList(
          subscription: subscription,
          useAppleStorePrices: useAppleStorePrices,
          applePriceForPlan: applePriceForPlan,
          isLoadingApplePrices: isLoadingApplePrices,
        ),
      ],
    );
  }
}

class _FreeUserSubscriptionBody extends StatelessWidget {
  const _FreeUserSubscriptionBody();

  @override
  Widget build(BuildContext context) {
    final user = Get.find<UserSessionController>().user.value;
    final planName = user?.activePlanLabel ?? 'Premium';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FadeSlideEntrance(index: 0, child: _SubscriptionHeader()),
        const SizedBox(height: 28),
        FadeSlideEntrance(
          index: 1,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: AppColors.cardSurfaceGradient,
              border: Border.all(color: AppColors.gold2, width: 1),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 40,
                  color: AppColors.goldBright,
                ),
                const SizedBox(height: 16),
                Text(
                  'You are a Free user',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading32Bold().copyWith(
                    fontSize: 22,
                    color: AppColors.textCream,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You can use all premium features on $planName.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    height: 1.35,
                    color: AppColors.textCream,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveSubscriptionBody extends StatelessWidget {
  const _ActiveSubscriptionBody({
    required this.subscription,
    required this.onCancel,
    required this.onManageApple,
  });

  final SubscriptionController subscription;
  final VoidCallback onCancel;
  final VoidCallback onManageApple;

  @override
  Widget build(BuildContext context) {
    final user = Get.find<UserSessionController>().user.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          final loading = subscription.isCancelling.value;
          final canCancel = subscription.canCancelSubscription;
          final canManageApple = subscription.canManageAppleSubscription;
          final historyLoading = subscription.isLoadingHistory.value;

          if (canManageApple) {
            return FadeSlideEntrance(
              index: 0,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: onManageApple,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.gold2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Manage in App Store',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldBright,
                    ),
                  ),
                ),
              ),
            );
          }

          return FadeSlideEntrance(
            index: 0,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: loading || historyLoading || !canCancel
                    ? null
                    : onCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE57373)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gold1,
                        ),
                      )
                    : Text(
                        'Cancel subscription',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE57373),
                        ),
                      ),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        FadeSlideEntrance(index: 1, child: _CurrentPlanSummaryCard(user: user)),
        const SizedBox(height: 28),
        FadeSlideEntrance(
          index: 2,
          child: Text(
            'Subscription history',
            style: AppTextStyles.heading32Bold().copyWith(
              fontSize: 20,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _TransactionHistorySection(subscription: subscription),
      ],
    );
  }
}

class _CurrentPlanSummaryCard extends StatelessWidget {
  const _CurrentPlanSummaryCard({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final planName = user?.activePlanLabel ?? 'Premium';
    final billing = user?.subscriptionType?.trim();
    final price = user?.packagePrice?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: AppColors.cardSurfaceGradient,
        border: Border.all(
          color: AppColors.subscriptionPlanBorderSelected,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active subscription',
            style: GoogleFonts.roboto(fontSize: 12, color: AppColors.textWolf),
          ),
          const SizedBox(height: 6),
          Text(
            planName,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textCream,
            ),
          ),
          if (billing != null && billing.isNotEmpty && billing != 'null') ...[
            const SizedBox(height: 4),
            Text(
              'Billed ${billing.toLowerCase()}',
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: AppColors.textWolf,
              ),
            ),
          ],
          if (price != null && price.isNotEmpty && price != 'null') ...[
            const SizedBox(height: 8),
            Text(
              r'$' + price,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.subscriptionPriceLabel,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionHistorySection extends StatelessWidget {
  const _TransactionHistorySection({required this.subscription});

  final SubscriptionController subscription;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (subscription.isLoadingHistory.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold1,
              ),
            ),
          ),
        );
      }

      final error = subscription.historyError.value;
      if (error != null && error.isNotEmpty) {
        return Text(
          error,
          style: GoogleFonts.roboto(fontSize: 14, color: AppColors.textWolf),
        );
      }

      final items = subscription.transactionHistory;
      if (items.isEmpty) {
        return Text(
          'No subscription history yet.',
          style: GoogleFonts.roboto(fontSize: 14, color: AppColors.textWolf),
        );
      }

      return Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            FadeSlideEntrance(
              index: 3 + i,
              child: _TransactionHistoryTile(item: items[i]),
            ),
            if (i < items.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    });
  }
}

class _TransactionHistoryTile extends StatelessWidget {
  const _TransactionHistoryTile({required this.item});

  final PackageTransactionModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: AppColors.cardSurfaceGradient,
        border: Border.all(
          color: AppColors.subscriptionPlanBorderUnselected,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.packageName.isNotEmpty
                      ? item.packageName
                      : 'Subscription',
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textCream,
                  ),
                ),
              ),
              Text(
                item.displayAmount,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.subscriptionPriceLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatTransactionDate(item.displayTimestamp),
            style: GoogleFonts.roboto(fontSize: 12, color: AppColors.textWolf),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.displayStatus} · ${item.planType.isNotEmpty ? item.planType : item.packageType}',
            style: GoogleFonts.roboto(fontSize: 11, color: AppColors.textWolf),
          ),
        ],
      ),
    );
  }
}

/// Shown when an API returns `LIMIT_EXCEEDED` and routes here.
class _SubscriptionLimitBanner extends StatelessWidget {
  const _SubscriptionLimitBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold2, width: 1),
      ),
      child: Text(
        message,
        style: AppTextStyles.body16().copyWith(
          fontSize: 14,
          height: 1.35,
          color: AppColors.textCream,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SubscriptionHeader extends StatelessWidget {
  const _SubscriptionHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unlock Your',
          style: AppTextStyles.heading32Bold().copyWith(
            fontSize: 32,
            height: 1.05,
            color: AppColors.white,
          ),
        ),
        GradientText(
          'Whiskey Wisdom.',
          style: AppTextStyles.heading32Bold().copyWith(
            fontSize: 32,
            height: 1.05,
          ),
          gradient: AppColors.goldGradient,
        ),
        const SizedBox(height: 12),
        Text(
          'Join the club now and get 50% off on life time subscription',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.25,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.spans});

  final List<InlineSpan> spans;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BenefitCheckIcon(),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: AppColors.white,
              ),
              children: spans,
            ),
          ),
        ),
      ],
    );
  }
}

class _PackagePlanList extends StatelessWidget {
  const _PackagePlanList({
    required this.subscription,
    required this.useAppleStorePrices,
    required this.applePriceForPlan,
    required this.isLoadingApplePrices,
  });

  final SubscriptionController subscription;
  final bool useAppleStorePrices;
  final String? Function(SubscriptionPackageModel plan) applePriceForPlan;
  final bool isLoadingApplePrices;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (subscription.isLoadingPackages.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold1,
              ),
            ),
          ),
        );
      }

      final error = subscription.loadError.value;
      if (error != null && error.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            error,
            style: GoogleFonts.roboto(fontSize: 14, color: AppColors.textWolf),
          ),
        );
      }

      final plans = subscription.packages;
      if (plans.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No subscription plans available.',
            style: GoogleFonts.roboto(fontSize: 14, color: AppColors.textWolf),
          ),
        );
      }

      final selectedId = subscription.selectedPackageId.value;

      return Column(
        children: [
          for (var i = 0; i < plans.length; i++) ...[
            FadeSlideEntrance(
              index: 5 + i,
              child: _PricePlanCard(
                plan: plans[i],
                isSelected: plans[i].id == selectedId,
                onTap: () => subscription.selectPackage(plans[i].id),
                applePriceLabel: useAppleStorePrices
                    ? applePriceForPlan(plans[i])
                    : null,
                isLoadingApplePrice:
                    useAppleStorePrices && isLoadingApplePrices,
              ),
            ),
            if (i < plans.length - 1)
              const SizedBox(height: AppSubscriptionTheme.priceCardGap),
          ],
        ],
      );
    });
  }
}

/// Figma pricing cards 124:314 / 129:304 — 323×94 stacked plan rows.
class _PricePlanCard extends StatelessWidget {
  const _PricePlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
    this.applePriceLabel,
    this.isLoadingApplePrice = false,
  });

  final SubscriptionPackageModel plan;
  final bool isSelected;
  final VoidCallback onTap;
  final String? applePriceLabel;
  final bool isLoadingApplePrice;

  String get _renewalNote {
    final storePrice = applePriceLabel?.trim();
    if (storePrice != null && storePrice.isNotEmpty) {
      return 'After trial will renew at $storePrice';
    }
    return plan.renewalNote;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        height: AppSubscriptionTheme.priceCardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            AppSubscriptionTheme.priceCardRadius,
          ),
          gradient: AppColors.cardSurfaceGradient,
          border: Border.all(
            color: isSelected
                ? AppColors.subscriptionPlanBorderSelected
                : AppColors.subscriptionPlanBorderUnselected,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 13, 14, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.displayTitle,
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: AppColors.textCream,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plan.billingSubtitle,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                            color: AppColors.textCream,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TrialPriceLabel(
                    priceLabel: applePriceLabel ?? plan.displayPrice,
                    isStoreLocalized:
                        applePriceLabel != null && applePriceLabel!.isNotEmpty,
                    isLoading: isLoadingApplePrice,
                  ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      _renewalNote,
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        color: AppColors.textWolf,
                      ),
                    ),
                  ),
                  if (isSelected) const _PlanSelectionIndicator(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrialPriceLabel extends StatelessWidget {
  const _TrialPriceLabel({
    required this.priceLabel,
    this.isStoreLocalized = false,
    this.isLoading = false,
  });

  final String priceLabel;
  final bool isStoreLocalized;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.gold1,
        ),
      );
    }

    final label = isStoreLocalized ? priceLabel : '\$$priceLabel';
    return Text(
      label,
      textAlign: TextAlign.right,
      style: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1,
        color: AppColors.subscriptionPriceLabel,
      ),
    );
  }
}

/// Benefit list tick (Figma 29px) — icon only, no image asset.
class _BenefitCheckIcon extends StatelessWidget {
  const _BenefitCheckIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 29,
      height: 29,
      child: Icon(Icons.check_rounded, size: 29, color: AppColors.goldBright),
    );
  }
}

/// Selected plan only: gold circle + tick.
class _PlanSelectionIndicator extends StatelessWidget {
  const _PlanSelectionIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 23,
      height: 23,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.goldGradient,
      ),
      child: const Icon(Icons.check_rounded, size: 15, color: AppColors.black),
    );
  }
}
