import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/analytics/meta_app_events.dart';
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
import '../../core/platform/app_platform.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_subscription_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/animations/staggered_entrance.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_confirm_dialog.dart';
import '../../core/widgets/common_primary_button.dart';
import '../../core/widgets/gradient_text.dart';
import '../../data/models/package_transaction_model.dart';
import '../../data/models/plan_limits.dart';
import '../../data/models/razorpay_payment_create_model.dart';
import '../../data/models/subscription_package_model.dart';
import '../../data/models/subscription_payment_receipt.dart';
import '../../data/models/user_model.dart';
import '../../data/plan_pricing.dart';
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
part 'widgets/subscription_confirm.dart';
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
  final _appleProducts = <String, ProductDetails>{};

  bool get _isIosCheckout => Platform.isIOS;

  bool get _isPostAuth {
    final args = Get.arguments;
    return args is Map && args[AuthNavigation.postAuthSubscriptionArg] == true;
  }

  bool get _hasUsedTrial =>
      Get.find<UserSessionController>().user.value?.hasUsedTrial == true;

  /// Free days a new subscription to [plan] starts with: none once the
  /// user has had a trial.
  int _trialDaysFor(SubscriptionPackageModel plan) =>
      _hasUsedTrial ? 0 : plan.trialDays;

  bool get _isTrialOffer {
    final plan = _subscription.selectedPackage;
    return plan != null && _trialDaysFor(plan) > 0;
  }

  String get _checkoutButtonLabel =>
      _isTrialOffer ? 'Start free trial' : 'Subscribe';

  /// The checkout's ×: back to where the user came from. Right after sign-in
  /// the screen can't pop, so it asks to skip instead.
  void _closeCheckout() {
    if (_isPostAuth) {
      _openSkipConfirmation();
      return;
    }
    Get.back<void>();
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
        .expand(
          (plan) => [
            ?plan.appleStoreId,
            ?plan.offer?.appleStoreId,
          ],
        )
        .toSet();
    if (!mounted) return;
    setState(() => _isLoadingApplePrices = true);
    try {
      await service.loadProducts(productIds);
      if (!mounted) return;
      setState(() {
        _appleProducts
          ..clear()
          ..addAll({for (final p in service.products) p.id: p});
      });
    } finally {
      if (mounted) setState(() => _isLoadingApplePrices = false);
    }
  }

  /// What [plan] costs if bought now. While its offer runs, the offer is
  /// charged and the plan's own price is shown crossed out. On iOS both come
  /// from the App Store, and an offer without its own App Store product isn't
  /// shown there at all. Nor is one whose App Store product isn't cheaper.
  _PlanQuote _quoteFor(SubscriptionPackageModel plan) {
    final now = DateTime.now();
    if (_isIosCheckout) {
      final offer = plan.appleOfferAt(now);
      final base = _appleProducts[plan.appleStoreId];
      final regular = base == null ? _usd(plan.price) : _store(base);
      final offerProduct = offer == null
          ? null
          : _appleProducts[offer.appleStoreId];
      if (offerProduct == null ||
          (regular.amount != null && offerProduct.rawPrice >= regular.amount!)) {
        return _PlanQuote(charge: regular);
      }
      return _PlanQuote(
        charge: _store(offerProduct),
        regular: regular,
        offer: offer,
      );
    }
    final offer = plan.offerAt(now);
    final regular = _usd(plan.price);
    if (offer == null) return _PlanQuote(charge: regular);
    return _PlanQuote(charge: _usd(offer.price), regular: regular, offer: offer);
  }

  static _PlanPrice _store(ProductDetails product) => _PlanPrice(
    label: product.price,
    amount: product.rawPrice,
    symbol: product.currencySymbol,
  );

  static _PlanPrice _usd(String price) {
    final amount = double.tryParse(price);
    return _PlanPrice(
      label: amount == null ? '\$$price' : '\$${PlanPricing.amount(amount)}',
      amount: amount,
    );
  }

  /// What the last checkout charges, for the App Store receipt.
  double? _pendingChargeAmount;

  /// Free days the last checkout started with, read before the payment
  /// (a refreshed user has used the trial), so Meta gets StartTrial.
  int _pendingTrialDays = 0;

  /// The App Store product's currency, else US dollars.
  String _storeCurrency(String? productId) {
    final code = productId == null
        ? null
        : _iapService?.productForAppleId(productId)?.currencyCode.trim();
    return code == null || code.isEmpty ? PaymentCurrency.usd : code;
  }

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
      // A restore re-confirms an old purchase; only a new one is a sale.
      if (purchase.status == PurchaseStatus.purchased) {
        MetaAppEvents.subscribed(
          trial: _pendingTrialDays > 0,
          orderId: purchaseId,
          price: _pendingChargeAmount ?? double.tryParse(plan.price),
          currency: _storeCurrency(purchase.productID),
        );
      }
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
          amount: _pendingChargeAmount ?? double.tryParse(plan.price) ?? 0,
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

  Future<void> _startAppleCheckout(String? productId) async {
    final service = _iapService;
    if (service == null) return;

    // The plan has no App Store product set in admin > Packages.
    if (productId == null) {
      await AppSnackbar.error('This plan is not available on the App Store yet.');
      return;
    }

    if (!service.isAvailable) {
      await AppSnackbar.error('In-app purchases are not available.');
      return;
    }

    final product = service.productForAppleId(productId);
    if (product == null) {
      await _loadAppleProducts();
      final retryProduct = service.productForAppleId(productId);
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
      if (isPaid) {
        MetaAppEvents.subscribed(
          trial: _pendingTrialDays > 0,
          orderId: verified.localOrderId.trim().isNotEmpty
              ? verified.localOrderId
              : pending.localOrderId,
          price: pending.amount,
          currency: pending.currency.trim().isNotEmpty
              ? pending.currency
              : PaymentCurrency.usd,
        );
      }
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

    // Review first: due today, trial end, first charge, renewal.
    final quote = _quoteFor(plan);
    // Untyped: GetX builds GetPageRoute<dynamic>, so toNamed<bool> throws.
    final confirmed = await Get.toNamed(
      AppRoutes.subscriptionConfirm,
      arguments: SubscriptionConfirmArgs._(
        plan: plan,
        quote: quote,
        trialDays: _trialDaysFor(plan),
        included: [
          for (final row in _subscription.limits.value.comparisonRows())
            if (!row.premiumLocked) row.premium,
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _pendingChargeAmount = quote.charge.amount;
    _pendingTrialDays = _trialDaysFor(plan);
    final appleProductId = quote.offer?.appleStoreId ?? plan.appleStoreId;
    MetaAppEvents.initiatedCheckout(
      planId: plan.id,
      price: quote.charge.amount,
      currency: _isIosCheckout
          ? _storeCurrency(appleProductId)
          : PaymentCurrency.usd,
    );

    if (_isIosCheckout) {
      await _startAppleCheckout(appleProductId);
      return;
    }

    setState(() => _isCreatingPayment = true);
    try {
      final payment = await Get.find<PackageRepository>().createPayment(
        userId: userId,
        planType: plan.planTypeForPayment,
        amount: quote.offer?.price ?? plan.price,
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
                    if (showCheckout)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSubscriptionTheme.horizontalPadding - 12,
                          4,
                          AppSubscriptionTheme.horizontalPadding - 8,
                          0,
                        ),
                        child: _CheckoutTopBar(
                          onClose: _closeCheckout,
                          onRestore: _isIosCheckout && !_isVerifyingPayment
                              ? () => unawaited(_restoreApplePurchases())
                              : null,
                        ),
                      ),
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
                              : showCheckout
                              ? AppSpacing.xs
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
                                quoteFor: _quoteFor,
                                isLoadingStorePrices:
                                    _isIosCheckout && _isLoadingApplePrices,
                                trialDaysFor: _trialDaysFor,
                                onOfferEnded: () => setState(() {}),
                                checkoutButtonLabel: _checkoutButtonLabel,
                                isCheckoutLoading:
                                    _isCreatingPayment || _isVerifyingPayment,
                                onCheckout: _startCheckout,
                              ),
                      ),
                    ),
                    if (showCheckout &&
                        !_subscription.isBootstrapping.value) ...[
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
