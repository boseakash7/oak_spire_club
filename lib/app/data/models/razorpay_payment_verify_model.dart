/// `package/payment-verify` → `data` when `flag` is `RAZORPAY_PAYMENT_VERIFIED`.
class RazorpayPaymentVerifyModel {
  const RazorpayPaymentVerifyModel({
    required this.flag,
    required this.message,
    required this.localOrderId,
    required this.status,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpayPlanId,
    required this.verificationSource,
  });

  factory RazorpayPaymentVerifyModel.fromJson(Map<String, dynamic> json) {
    return RazorpayPaymentVerifyModel(
      flag: json['flag']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      localOrderId: json['local_order_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      razorpayOrderId: json['razorpay_order_id']?.toString() ?? '',
      razorpayPaymentId: json['razorpay_payment_id']?.toString() ?? '',
      razorpayPlanId: json['razorpay_plan_id']?.toString() ?? '',
      verificationSource: json['verification_source']?.toString() ?? '',
    );
  }

  final String flag;
  final String message;
  final String localOrderId;
  final String status;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpayPlanId;
  final String verificationSource;
}
