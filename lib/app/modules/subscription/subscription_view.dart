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
import '../../core/widgets/app_backdrop_image.dart';
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
import '../../core/widgets/app_pressable.dart';
import '../../core/animations/staggered_entrance.dart';
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

part 'widgets/subscription_bodies.dart';
part 'widgets/subscription_history.dart';
part 'widgets/subscription_plans.dart';

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

  String get _checkoutButtonLabel =>
      _isTrialOffer ? 'Continue Free trial before expires' : 'Subscribe';

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
            const AppBackdropImage(
              AppAssets.subscriptionBackground,
              fallbackAsset: AppAssets.signUpBackground,
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
