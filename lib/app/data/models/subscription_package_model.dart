import '../../core/constants/app_constants.dart';

/// `package/get-all` row (bourboneur `Package`).
class SubscriptionPackageModel {
  const SubscriptionPackageModel({
    required this.id,
    required this.name,
    required this.price,
    required this.packageType,
    this.appleStoreId,
  });

  factory SubscriptionPackageModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPackageModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      packageType: json['package_type']?.toString().toLowerCase() ?? '',
      appleStoreId: json['apple_store_id']?.toString(),
    );
  }

  final String id;
  final String name;
  final String price;
  /// `monthly` | `yearly` — sent as `plan_type` to `package/payment-create`.
  final String packageType;
  final String? appleStoreId;

  bool get isYearly => packageType == 'yearly';

  String get displayTitle {
    if (name.trim().isNotEmpty) return name.trim();
    return isYearly ? 'Yearly' : 'Monthly';
  }

  String get billingSubtitle =>
      isYearly ? 'Billed every year' : 'Billed every month';

  String get renewalNote => 'After trial will renew at \$$displayPrice';

  String get displayPrice {
    final parsed = double.tryParse(price);
    if (parsed == null) return price;
    if (parsed == parsed.roundToDouble()) return parsed.toInt().toString();
    return parsed.toStringAsFixed(2);
  }

  int get displayPriceInt {
    final parsed = double.tryParse(price);
    return parsed?.round() ?? 0;
  }

  /// `plan_type` for payment-create (falls back to package type).
  String get planTypeForPayment =>
      packageType.isNotEmpty ? packageType : (isYearly ? 'yearly' : 'monthly');

  /// App Store product id from API, or known defaults (`monthly_sub` / `yearly_plan`).
  String get appleProductId {
    final fromApi = appleStoreId?.trim();
    if (fromApi != null &&
        fromApi.isNotEmpty &&
        fromApi.toLowerCase() != 'null') {
      return fromApi;
    }
    return isYearly
        ? AppConstants.appleYearlyProductId
        : AppConstants.appleMonthlyProductId;
  }
}
