int _parseInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _parseNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

/// One row from `package/transaction-history` → `data.history[]`.
class PackageTransactionModel {
  const PackageTransactionModel({
    required this.transactionId,
    required this.localOrderId,
    required this.userId,
    required this.packageId,
    required this.packageName,
    required this.packagePlan,
    required this.packageType,
    required this.amount,
    required this.paymentMethod,
    this.paymentGateway,
    required this.purchasedAt,
    required this.orderCreatedAt,
    required this.transactionCreatedAt,
    required this.status,
    required this.currency,
    required this.planType,
    this.internalReference,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpayPlanId,
    this.razorpaySubscriptionId,
    this.razorpaySubscriptionStatus,
    this.trialDays,
    this.trialStartAt,
    this.verifiedAt,
    this.cancelledAt,
    this.verificationSource,
    this.verificationMessage,
  });

  factory PackageTransactionModel.fromJson(Map<String, dynamic> json) {
    return PackageTransactionModel(
      transactionId: _parseInt(json['transaction_id']),
      localOrderId: _parseInt(json['local_order_id']),
      userId: _parseInt(json['user_id']),
      packageId: _parseInt(json['package_id']),
      packageName: json['package_name']?.toString() ?? '',
      packagePlan: json['package_plan']?.toString() ?? '',
      packageType: json['package_type']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentGateway: json['payment_gateway']?.toString(),
      purchasedAt: _parseInt(json['purchased_at']),
      orderCreatedAt: _parseInt(json['order_created_at']),
      transactionCreatedAt: _parseInt(json['transaction_created_at']),
      status: json['status']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      planType: json['plan_type']?.toString() ?? '',
      internalReference: json['internal_reference']?.toString(),
      razorpayOrderId: json['razorpay_order_id']?.toString(),
      razorpayPaymentId: json['razorpay_payment_id']?.toString(),
      razorpayPlanId: json['razorpay_plan_id']?.toString(),
      razorpaySubscriptionId: json['razorpay_subscription_id']?.toString(),
      razorpaySubscriptionStatus: json['razorpay_subscription_status']
          ?.toString(),
      trialDays: _parseNullableInt(json['trial_days']),
      trialStartAt: _parseNullableInt(json['trial_start_at']),
      verifiedAt: _parseNullableInt(json['verified_at']),
      cancelledAt: _parseNullableInt(json['cancelled_at']),
      verificationSource: json['verification_source']?.toString(),
      verificationMessage: json['verification_message']?.toString(),
    );
  }

  final int transactionId;
  final int localOrderId;
  final int userId;
  final int packageId;
  final String packageName;
  final String packagePlan;
  final String packageType;
  final double amount;
  final String paymentMethod;
  final String? paymentGateway;
  final int purchasedAt;
  final int orderCreatedAt;
  final int transactionCreatedAt;
  final String status;
  final String currency;
  final String planType;
  final String? internalReference;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpayPlanId;
  final String? razorpaySubscriptionId;
  final String? razorpaySubscriptionStatus;
  final int? trialDays;
  final int? trialStartAt;
  final int? verifiedAt;
  final int? cancelledAt;
  final String? verificationSource;
  final String? verificationMessage;

  /// Prefer `purchased_at` when set; otherwise `order_created_at`.
  int get displayTimestamp {
    if (purchasedAt > 0) return purchasedAt;
    if (orderCreatedAt > 0) return orderCreatedAt;
    return transactionCreatedAt;
  }

  String get displayAmount {
    final symbol = currency.toUpperCase() == 'INR' ? '₹' : r'$';
    if (amount == amount.roundToDouble()) {
      return '$symbol${amount.toInt()}';
    }
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  String get displayStatus {
    final raw = status.trim();
    if (raw.isEmpty) return '—';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  /// Non-empty Razorpay subscription id from transaction history.
  String? get validRazorpaySubscriptionId {
    final id = razorpaySubscriptionId?.trim();
    if (id == null || id.isEmpty || id == 'null') return null;
    return id;
  }

  /// `payment_gateway` from transaction history, with `payment_method` fallback.
  String? get resolvedPaymentGateway {
    final gateway = paymentGateway?.trim().toLowerCase();
    if (gateway != null && gateway.isNotEmpty && gateway != 'null') {
      return gateway;
    }
    final method = paymentMethod.trim().toLowerCase();
    if (method == 'apple_in_app' || method == 'razorpay') return method;
    return null;
  }
}

/// Picks `razorpay_subscription_id` for `package/cancel-subscription`.
extension PackageTransactionHistoryCancel on List<PackageTransactionModel> {
  static const _preferredStatuses = {'paid', 'active', 'subscribed', 'verified'};

  String? resolveRazorpaySubscriptionIdForCancel() {
    final withId = where((t) => t.validRazorpaySubscriptionId != null).toList();
    if (withId.isEmpty) return null;

    for (final item in withId) {
      if (_preferredStatuses.contains(item.status.trim().toLowerCase())) {
        return item.validRazorpaySubscriptionId;
      }
    }
    return withId.first.validRazorpaySubscriptionId;
  }

  /// `payment_gateway` from the active subscription transaction row.
  String? resolvePaymentGatewayForCancel() {
    if (isEmpty) return null;

    for (final item in this) {
      if (_preferredStatuses.contains(item.status.trim().toLowerCase())) {
        final gateway = item.resolvedPaymentGateway;
        if (gateway != null) return gateway;
      }
    }

    for (final item in this) {
      final gateway = item.resolvedPaymentGateway;
      if (gateway != null) return gateway;
    }

    return null;
  }
}

/// Envelope from `package/transaction-history` → `data`.
class PackageTransactionHistoryResult {
  const PackageTransactionHistoryResult({
    required this.flag,
    required this.message,
    required this.userId,
    required this.count,
    required this.history,
    this.paymentGateway,
  });

  factory PackageTransactionHistoryResult.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['history'];
    final items = <PackageTransactionModel>[];
    if (rawHistory is List) {
      for (final row in rawHistory) {
        if (row is Map) {
          items.add(
            PackageTransactionModel.fromJson(Map<String, dynamic>.from(row)),
          );
        }
      }
    }

    return PackageTransactionHistoryResult(
      flag: json['flag']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      userId: _parseInt(json['user_id']),
      count: _parseInt(json['count']),
      history: items,
      paymentGateway: json['payment_gateway']?.toString(),
    );
  }

  final String flag;
  final String message;
  final int userId;
  final int count;
  final List<PackageTransactionModel> history;
  final String? paymentGateway;

  String? get resolvedPaymentGateway {
    final gateway = paymentGateway?.trim().toLowerCase();
    if (gateway != null && gateway.isNotEmpty && gateway != 'null') {
      return gateway;
    }
    return history.resolvePaymentGatewayForCancel();
  }
}
