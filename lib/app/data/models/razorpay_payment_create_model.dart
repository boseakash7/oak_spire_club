import '../../core/constants/payment_currency.dart';

/// `package/payment-create` → `data` when `flag` is `RAZORPAY_PAYMENT_CREATED`
/// or `RAZORPAY_TRIAL_SUBSCRIPTION_CREATED`.
class RazorpayPaymentCreateModel {
  const RazorpayPaymentCreateModel({
    required this.flag,
    required this.message,
    required this.localOrderId,
    required this.internalReference,
    required this.userId,
    required this.packageId,
    required this.planType,
    required this.amount,
    required this.currency,
    required this.keyId,
    required this.planCreated,
    required this.razorpayPlanId,
    required this.razorpayPlanStatus,
    this.razorpayPlanError,
    required this.razorpayOrderId,
    required this.razorpayOrderStatus,
    required this.subscriptionCreated,
    required this.razorpaySubscriptionId,
    required this.razorpaySubscriptionStatus,
    this.razorpaySubscriptionShortUrl,
    this.razorpaySubscriptionError,
    this.razorpaySubscriptionChargeAt,
    this.trialDays,
    this.trialStartAt,
    this.subscriptionStartAt,
    required this.checkoutEntity,
  });

  factory RazorpayPaymentCreateModel.fromJson(Map<String, dynamic> json) {
    return RazorpayPaymentCreateModel(
      flag: json['flag']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      localOrderId: json['local_order_id']?.toString() ?? '',
      internalReference: json['internal_reference']?.toString() ?? '',
      userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      packageId: int.tryParse(json['package_id']?.toString() ?? '') ?? 0,
      planType: json['plan_type']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      currency: json['currency']?.toString().toUpperCase() ?? PaymentCurrency.usd,
      keyId: json['key_id']?.toString() ?? '',
      planCreated: json['plan_created'] == true ||
          json['plan_created']?.toString() == '1' ||
          json['plan_created']?.toString().toLowerCase() == 'true',
      razorpayPlanId: json['razorpay_plan_id']?.toString() ?? '',
      razorpayPlanStatus: json['razorpay_plan_status']?.toString() ?? '',
      razorpayPlanError: json['razorpay_plan_error']?.toString(),
      razorpayOrderId: json['razorpay_order_id']?.toString() ?? '',
      razorpayOrderStatus: json['razorpay_order_status']?.toString() ?? '',
      subscriptionCreated: json['subscription_created'] == true ||
          json['subscription_created']?.toString() == '1' ||
          json['subscription_created']?.toString().toLowerCase() == 'true',
      razorpaySubscriptionId: json['razorpay_subscription_id']?.toString() ?? '',
      razorpaySubscriptionStatus:
          json['razorpay_subscription_status']?.toString() ?? '',
      razorpaySubscriptionShortUrl:
          json['razorpay_subscription_short_url']?.toString(),
      razorpaySubscriptionError: json['razorpay_subscription_error']?.toString(),
      razorpaySubscriptionChargeAt:
          int.tryParse(json['razorpay_subscription_charge_at']?.toString() ?? ''),
      trialDays: int.tryParse(json['trial_days']?.toString() ?? ''),
      trialStartAt: int.tryParse(json['trial_start_at']?.toString() ?? ''),
      subscriptionStartAt:
          int.tryParse(json['subscription_start_at']?.toString() ?? ''),
      checkoutEntity: json['checkout_entity']?.toString() ?? '',
    );
  }

  final String flag;
  final String message;
  final String localOrderId;
  final String internalReference;
  final int userId;
  final int packageId;
  final String planType;
  final double amount;
  final String currency;
  final String keyId;
  final bool planCreated;
  final String razorpayPlanId;
  final String razorpayPlanStatus;
  final String? razorpayPlanError;
  final String razorpayOrderId;
  final String razorpayOrderStatus;
  final bool subscriptionCreated;
  final String razorpaySubscriptionId;
  final String razorpaySubscriptionStatus;
  final String? razorpaySubscriptionShortUrl;
  final String? razorpaySubscriptionError;
  final int? razorpaySubscriptionChargeAt;
  final int? trialDays;
  final int? trialStartAt;
  final int? subscriptionStartAt;
  final String checkoutEntity;

  /// USD from API — same value Razorpay order was created with (no ×100 conversion).
  int get razorpayAmount => amount.round();

  bool get isSubscriptionCheckout =>
      checkoutEntity.trim().toLowerCase() == 'subscription' ||
      (razorpaySubscriptionId.trim().isNotEmpty &&
          razorpayOrderId.trim().isEmpty);

  bool get hasValidCheckout {
    if (keyId.trim().isEmpty) return false;
    if (isSubscriptionCheckout) {
      return razorpaySubscriptionId.trim().isNotEmpty;
    }
    return razorpayOrderId.trim().isNotEmpty;
  }

  /// Backward-compatible alias for order and subscription checkout.
  bool get hasValidOrder => hasValidCheckout;
}
