import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  bool get _isTrialOffer {
    final user = Get.find<UserSessionController>().user.value;
    return user?.hasUsedTrial != true;
  }

  String get _checkoutButtonLabel => _isTrialOffer
      ? 'Continue Free trial before expires'
      : 'Subscribe';

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
    final subscriptionId = res.data?['razorpay_subscription_id']
        ?.toString()
        .trim();
    unawaited(
      _submitPaymentVerify(
        status: 'paid',
        razorpayPaymentId: res.paymentId?.trim() ?? '',
        razorpayOrderId: res.orderId?.trim(),
        razorpaySubscriptionId: subscriptionId,
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
    String? razorpaySubscriptionId,
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
      final resolvedOrderId = razorpayOrderId?.trim();
      final resolvedSubscriptionId = razorpaySubscriptionId?.trim();
      final verified = await Get.find<PackageRepository>().verifyPayment(
        localOrderId: pending.localOrderId,
        status: status,
        razorpayOrderId: resolvedOrderId?.isNotEmpty == true
            ? resolvedOrderId!
            : pending.razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpayPlanId: pending.razorpayPlanId,
        razorpaySubscriptionId: resolvedSubscriptionId?.isNotEmpty == true
            ? resolvedSubscriptionId!
            : pending.razorpaySubscriptionId,
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

  Future<void> _handleCancelSubscription() async {
    if (_subscription.isAppleInAppGateway) {
      if (Platform.isIOS) {
        await AppStoreLauncher.openAppleSubscriptions();
      } else {
        await AppSnackbar.info(
          'Please log in to an Apple device to cancel your subscription.',
        );
      }
      return;
    }

    if (_subscription.isRazorpayGateway) {
      await _confirmCancelSubscription();
      return;
    }

    await AppSnackbar.error(
      'Unable to cancel subscription. Please contact support.',
    );
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

      if (!payment.hasValidCheckout) {
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
        'name': AppConstants.appName,
        'description': '${plan.displayTitle} subscription',
        'prefill': <String, Object?>{'contact': '', 'email': ''},
        'theme': <String, Object?>{'color': '#B9861F'},
      };

      if (payment.isSubscriptionCheckout) {
        options['subscription_id'] = payment.razorpaySubscriptionId;
      } else {
        options['order_id'] = payment.razorpayOrderId;
        options['amount'] = payment.razorpayAmount;
        options['currency'] = payment.currency;
      }

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
                                onCancel: () =>
                                    unawaited(_handleCancelSubscription()),
                              )
                            : _CheckoutSubscriptionBody(
                                subscription: _subscription,
                                useAppleStorePrices: _isIosCheckout,
                                applePriceForPlan: _applePriceForPlan,
                                isLoadingApplePrices: _isLoadingApplePrices,
                                isTrialOffer: _isTrialOffer,
                                checkoutButtonLabel: _checkoutButtonLabel,
                                isCheckoutLoading:
                                    _isCreatingPayment || _isVerifyingPayment,
                                onCheckout: _startCheckout,
                              ),
                      ),
                    ),
                    if (showCheckout &&
                        !_subscription.isBootstrapping.value) ...[
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
                        child: const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: _SkipThisForNowLink(),
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
    required this.isTrialOffer,
    required this.checkoutButtonLabel,
    required this.isCheckoutLoading,
    required this.onCheckout,
  });

  final SubscriptionController subscription;
  final bool useAppleStorePrices;
  final String? Function(SubscriptionPackageModel plan) applePriceForPlan;
  final bool isLoadingApplePrices;
  final bool isTrialOffer;
  final String checkoutButtonLabel;
  final bool isCheckoutLoading;
  final VoidCallback onCheckout;

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
        const SizedBox(height: 18),
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
        const SizedBox(height: 18),
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
        const SizedBox(height: 18),
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
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSubscriptionTheme.planBlockInset,
          ),
          child: _PackagePlanList(
            subscription: subscription,
            useAppleStorePrices: useAppleStorePrices,
            applePriceForPlan: applePriceForPlan,
            isLoadingApplePrices: isLoadingApplePrices,
          ),
        ),
        if (isTrialOffer) ...[
          const SizedBox(height: 36),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSubscriptionTheme.planBlockInset,
            ),
            child: _TrialUrgencySection(),
          ),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 36),
        CommonPrimaryButton(
          label: checkoutButtonLabel,
          isLoading: isCheckoutLoading,
          onPressed: onCheckout,
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1,
            color: AppColors.black,
          ),
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
  });

  final SubscriptionController subscription;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final user = Get.find<UserSessionController>().user.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          final loading = subscription.isCancelling.value;
          final canCancel = subscription.canCancelSubscription;
          final historyLoading = subscription.isLoadingHistory.value;
          final needsHistory = subscription.isRazorpayGateway;

          return FadeSlideEntrance(
            index: 0,
            child: _CurrentPlanSummaryCard(
              user: user,
              actionLabel: 'Cancel subscription',
              onAction: onCancel,
              actionLoading: loading,
              actionEnabled:
                  canCancel && (!needsHistory || !historyLoading),
              showAction: subscription.canShowCancelSubscription,
            ),
          );
        }),
        const SizedBox(height: 28),
        FadeSlideEntrance(
          index: 1,
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
  const _CurrentPlanSummaryCard({
    required this.user,
    this.actionLabel,
    this.onAction,
    this.actionLoading = false,
    this.actionEnabled = true,
    this.showAction = false,
  });

  final UserModel? user;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool actionLoading;
  final bool actionEnabled;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final planName = user?.activePlanLabel ?? 'Premium';
    final billing = user?.subscriptionType?.trim();
    final price = user?.packagePrice?.trim();
    final isDestructiveAction =
        actionLabel?.toLowerCase().contains('cancel') == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: AppColors.cardSurfaceGradient,
        border: Border.all(
          color: AppColors.subscriptionPlanBorderSelected,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          if (showAction &&
              actionLabel != null &&
              actionLabel!.isNotEmpty &&
              onAction != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: actionEnabled && !actionLoading ? onAction : null,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: actionLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gold1,
                          ),
                        )
                      : Text(
                          actionLabel!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: actionEnabled
                                ? (isDestructiveAction
                                      ? const Color(0xFFE57373)
                                      : AppColors.subscriptionSkipLink)
                                : AppColors.textWolf.withValues(alpha: 0.5),
                          ),
                        ),
                ),
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
            fontSize: 28,
            height: 1.5,
            color: AppColors.white,
          ),
        ),
        GradientText(
          'Whiskey Wisdom.',
          style: AppTextStyles.heading32Bold().copyWith(
            fontSize: 28,
            height: 1.5,
          ),
          gradient: AppColors.goldGradient,
        ),
        Text(
          'Join the club now and get 50% off on life time subscription',
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
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
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: _BenefitCheckIcon(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.5,
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
      final bestValueIndex = plans.indexWhere((plan) => !plan.isYearly);

      return Column(
        children: [
          for (var i = 0; i < plans.length; i++) ...[
            FadeSlideEntrance(
              index: 5 + i,
              child: _PricePlanCard(
                plan: plans[i],
                isSelected: plans[i].id == selectedId,
                showBestValue: i == bestValueIndex,
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

/// Figma pricing cards 124:314 / 196:284 — 323×58 stacked plan rows.
class _PricePlanCard extends StatelessWidget {
  const _PricePlanCard({
    required this.plan,
    required this.isSelected,
    required this.showBestValue,
    required this.onTap,
    this.applePriceLabel,
    this.isLoadingApplePrice = false,
  });

  final SubscriptionPackageModel plan;
  final bool isSelected;
  final bool showBestValue;
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
    final card = AnimatedPressable(
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
          padding: const EdgeInsets.fromLTRB(15, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      plan.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plan.billingSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        color: AppColors.subscriptionBillingSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TrialPriceLabel(
                priceLabel: applePriceLabel ?? plan.displayPrice,
                salePrice: double.tryParse(plan.price),
                isStoreLocalized:
                    applePriceLabel != null && applePriceLabel!.isNotEmpty,
                isLoading: isLoadingApplePrice,
                renewalNote: _renewalNote,
              ),
              SizedBox(
                width: 30,
                child: isSelected
                    ? const Center(child: _PlanSelectionIndicator())
                    : null,
              ),
            ],
          ),
        ),
      ),
    );

    if (!showBestValue) return card;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSubscriptionTheme.bestValueBadgeOverlap,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          const Positioned(
            top: -10,
            left: 26,
            child: IgnorePointer(child: _BestValueBadge()),
          ),
        ],
      ),
    );
  }
}

class _TrialPriceLabel extends StatelessWidget {
  const _TrialPriceLabel({
    required this.priceLabel,
    required this.renewalNote,
    this.salePrice,
    this.isStoreLocalized = false,
    this.isLoading = false,
  });

  static const double _originalPriceMultiplier = 1.5;

  final String priceLabel;
  final double? salePrice;
  final bool isStoreLocalized;
  final bool isLoading;
  final String renewalNote;

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) return amount.toInt().toString();
    return amount.toStringAsFixed(2);
  }

  String _leadingCurrencySymbol(String label) {
    final trimmed = label.trim();
    var end = 0;
    while (end < trimmed.length) {
      final code = trimmed.codeUnitAt(end);
      final isDigit = code >= 48 && code <= 57;
      if (isDigit || code == 32) break;
      end++;
    }
    if (end == 0) return r'$';
    return trimmed.substring(0, end);
  }

  String? _originalPriceLabel(String saleLabel) {
    final basePrice = salePrice;
    if (basePrice == null || basePrice <= 0) return null;

    final originalAmount = basePrice * _originalPriceMultiplier;
    final formattedAmount = _formatAmount(originalAmount);

    if (isStoreLocalized) {
      return '${_leadingCurrencySymbol(saleLabel)}$formattedAmount';
    }

    return r'$' + formattedAmount;
  }

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

    final label = isStoreLocalized ? priceLabel : r'$' + priceLabel;
    final originalLabel = _originalPriceLabel(label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              textAlign: TextAlign.right,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: AppColors.subscriptionPriceLabel,
              ),
            ),
            if (originalLabel != null) ...[
              const SizedBox(width: 4),
              Text(
                originalLabel,
                textAlign: TextAlign.right,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1,
                  color: AppColors.textWolf,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.textWolf,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          renewalNote,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: GoogleFonts.roboto(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            height: 1.06,
            color: AppColors.textWolf,
          ),
        ),
      ],
    );
  }
}

class _BestValueBadge extends StatelessWidget {
  const _BestValueBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      height: 20,
      padding: const EdgeInsets.only(left: 6, right: 8),
      decoration: BoxDecoration(
        color: AppColors.subscriptionPlanBorderSelected,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppAssets.subscriptionCrown,
            width: 13.3,
            height: 12,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 5),
          Text(
            'Best Value',
            style: GoogleFonts.playfairDisplay(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              height: 1,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrialUrgencySection extends StatefulWidget {
  const _TrialUrgencySection();

  @override
  State<_TrialUrgencySection> createState() => _TrialUrgencySectionState();
}

class _TrialUrgencySectionState extends State<_TrialUrgencySection> {
  static const Duration _period = Duration(hours: 4);
  static const int _slotsLeft = 9;

  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _resolveEndMillis() {
    final now = DateTime.now().millisecondsSinceEpoch;
    var end = AppStorage.trialCountdownEndsAtMillis;
    if (end == null) {
      end = now + _period.inMilliseconds;
      unawaited(AppStorage.setTrialCountdownEndsAtMillis(end));
      return end;
    }

    final periodMs = _period.inMilliseconds;
    if (end <= now) {
      final elapsed = now - end;
      final cycles = (elapsed ~/ periodMs) + 1;
      end += cycles * periodMs;
      unawaited(AppStorage.setTrialCountdownEndsAtMillis(end));
    }
    return end;
  }

  void _tick() {
    final remaining = Duration(
      milliseconds: _resolveEndMillis() - DateTime.now().millisecondsSinceEpoch,
    );
    if (!mounted) return;
    setState(() {
      _remaining = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  String get _formattedRemaining {
    var seconds = _remaining.inSeconds;
    if (seconds < 0) seconds = 0;
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  double get _progress {
    final total = _period.inMilliseconds;
    if (total <= 0) return 0;
    return (_remaining.inMilliseconds / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: AppColors.white,
            ),
            children: [
              const TextSpan(text: 'Free trials expire in '),
              TextSpan(
                text: _formattedRemaining,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: AppColors.subscriptionTrialTime,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            height: 8,
            width: double.infinity,
            child: ColoredBox(
              color: AppColors.subscriptionTrialTrack,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: _progress,
                  heightFactor: 1,
                  child: const ColoredBox(
                    color: AppColors.subscriptionPlanBorderSelected,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Only $_slotsLeft free trials slots left today.',
          style: GoogleFonts.roboto(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            height: 1.2,
            color: AppColors.subscriptionBenefitGold,
          ),
        ),
      ],
    );
  }
}

class _SkipThisForNowLink extends StatelessWidget {
  const _SkipThisForNowLink();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.flip(
          flipX: true,
          child: SvgPicture.asset(
            AppAssets.subscriptionSkipChevron,
            width: 9,
            height: 14,
            fit: BoxFit.fill,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Skip this for now',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1,
            color: AppColors.subscriptionSkipLink,
          ),
        ),
      ],
    );
  }
}

/// Benefit list tick (Figma 29px) — exported check vector in 29×29 frame.
class _BenefitCheckIcon extends StatelessWidget {
  const _BenefitCheckIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 7, 3.5, 7.5),
        child: SvgPicture.asset(
          AppAssets.subscriptionBenefitCheck,
          width: 19.53,
          height: 13.5,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}

/// Selected plan only: gold circle + tick from Figma.
class _PlanSelectionIndicator extends StatelessWidget {
  const _PlanSelectionIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: SvgPicture.asset(
        AppAssets.subscriptionPlanCheck,
        width: 22,
        height: 22,
        fit: BoxFit.contain,
      ),
    );
  }
}
