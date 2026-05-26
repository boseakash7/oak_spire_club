/// Display model for the subscription payment success receipt.
class SubscriptionPaymentReceipt {
  const SubscriptionPaymentReceipt({
    required this.merchantName,
    required this.planTitle,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paidAt,
    required this.localOrderId,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
  });

  factory SubscriptionPaymentReceipt.fromArguments(Map<dynamic, dynamic> map) {
    return SubscriptionPaymentReceipt(
      merchantName: map['merchantName']?.toString() ?? '',
      planTitle: map['planTitle']?.toString() ?? '',
      amount: double.tryParse(map['amount']?.toString() ?? '') ?? 0,
      currency: map['currency']?.toString().toUpperCase() ?? 'USD',
      status: map['status']?.toString() ?? '',
      paidAt: DateTime.tryParse(map['paidAt']?.toString() ?? '') ?? DateTime.now(),
      localOrderId: map['localOrderId']?.toString() ?? '',
      razorpayOrderId: map['razorpayOrderId']?.toString() ?? '',
      razorpayPaymentId: map['razorpayPaymentId']?.toString() ?? '',
    );
  }

  final String merchantName;
  final String planTitle;
  final double amount;
  final String currency;
  final String status;
  final DateTime paidAt;
  final String localOrderId;
  final String razorpayOrderId;
  final String razorpayPaymentId;

  Map<String, dynamic> toArguments() => {
        'merchantName': merchantName,
        'planTitle': planTitle,
        'amount': amount,
        'currency': currency,
        'status': status,
        'paidAt': paidAt.toIso8601String(),
        'localOrderId': localOrderId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
      };

  String get formattedAmount {
    final value = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
    if (currency == 'USD') return '\$$value';
    return '$value $currency';
  }

  bool get isPaid => status.trim().toLowerCase() == 'paid';

  bool get isFailed => status.trim().toLowerCase() == 'failed';

  String get displayStatus {
    final s = status.trim();
    if (s.isEmpty) return 'Paid';
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  String get displayPaymentId {
    final id = razorpayPaymentId.trim();
    return id.isEmpty ? '—' : id;
  }
}
