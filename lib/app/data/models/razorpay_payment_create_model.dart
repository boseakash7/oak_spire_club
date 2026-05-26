import '../../core/constants/payment_currency.dart';

/// `package/payment-create` → `data` when `flag` is `RAZORPAY_PAYMENT_CREATED`.
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

  /// USD from API — same value Razorpay order was created with (no ×100 conversion).
  int get razorpayAmount => amount.round();

  bool get hasValidOrder =>
      razorpayOrderId.trim().isNotEmpty && keyId.trim().isNotEmpty;
}
