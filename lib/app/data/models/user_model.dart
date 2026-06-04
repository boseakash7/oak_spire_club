class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.packageId,
    this.customerId,
    this.paymentMethodId,
    this.status,
    this.packageType,
    this.packagePrice,
    this.subscriptionType,
    this.lastPaymentMethod,
    this.subscriptionStatus,
    this.isFree,
    this.gender,
    this.packageName,
    this.createdAt,
  });

  final String id;
  final String? name;
  final String? email;
  final String? gender;
  final String? packageId;
  final String? customerId;
  final String? paymentMethodId;
  final String? status;
  final String? packageType;
  final String? packagePrice;
  final String? subscriptionType;
  final String? lastPaymentMethod;
  final String? subscriptionStatus;
  final String? isFree;
  final String? packageName;
  final String? createdAt;

  /// Backend granted free premium (`is_free` = `1`).
  bool get isFreeUser {
    final raw = isFree?.trim().toLowerCase();
    return raw == '1' || raw == 'true';
  }

  /// Active paid subscription (`subscription_status` = `subscribed`).
  bool get hasActiveSubscription {
    final raw = subscriptionStatus?.trim().toLowerCase();
    return raw == 'subscribed' || raw == 'active' || raw == 'paid';
  }

  String get activePlanLabel {
    final name = packageName?.trim();
    if (name != null && name.isNotEmpty && name != 'null') return name;
    final type = subscriptionType?.trim();
    if (type != null && type.isNotEmpty && type != 'null') {
      return type[0].toUpperCase() + type.substring(1);
    }
    return 'Premium';
  }

  /// No paid package — show subscription offer after auth.
  bool get needsSubscriptionOffer {
    if (isFreeUser) return false;
    final pkg = packageId?.trim();
    if (pkg != null && pkg.isNotEmpty && pkg != 'null') return false;
    final sub = subscriptionStatus?.trim().toLowerCase();
    if (sub == 'active' || sub == 'subscribed' || sub == 'paid') {
      return false;
    }
    return true;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      packageId: json['package_id']?.toString(),
      paymentMethodId: json['payment_method_id']?.toString(),
      customerId: json['customer_id']?.toString(),
      status: json['status']?.toString(),
      packageType: json['package_type']?.toString(),
      packagePrice: json['package_price']?.toString(),
      subscriptionType: json['subscription_type']?.toString(),
      lastPaymentMethod: json['last_payment_method']?.toString(),
      subscriptionStatus: json['subscription_status']?.toString(),
      isFree: json['is_free']?.toString(),
      gender: json['gender']?.toString(),
      packageName: json['package_name']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? gender,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      packageId: packageId,
      customerId: customerId,
      paymentMethodId: paymentMethodId,
      status: status,
      packageType: packageType,
      packagePrice: packagePrice,
      subscriptionType: subscriptionType,
      lastPaymentMethod: lastPaymentMethod,
      subscriptionStatus: subscriptionStatus,
      isFree: isFree,
      gender: gender ?? this.gender,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'package_id': packageId,
        'customer_id': customerId,
        'payment_method_id': paymentMethodId,
        'status': status,
        'package_type': packageType,
        'package_price': packagePrice,
        'subscription_type': subscriptionType,
        'last_payment_method': lastPaymentMethod,
        'subscription_status': subscriptionStatus,
        'is_free': isFree,
        'gender': gender,
        'package_name': packageName,
        'created_at': createdAt,
      };
}

