import '../../core/constants/app_constants.dart';

/// `package/get-all` row (bourboneur `Package`).
class SubscriptionPackageModel {
  const SubscriptionPackageModel({
    required this.id,
    required this.name,
    required this.price,
    required this.packageType,
    this.appleStoreId,
    this.offer,
    this.trialDays = defaultTrialDays,
  });

  /// The server's default (`razorpay_trial_days`), for a server that doesn't
  /// send `trial_days` yet.
  static const int defaultTrialDays = 7;

  factory SubscriptionPackageModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPackageModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      packageType: json['package_type']?.toString().toLowerCase() ?? '',
      appleStoreId: json['apple_store_id']?.toString(),
      offer: PackageOffer.fromJson(json['offer']),
      trialDays:
          int.tryParse(json['trial_days']?.toString() ?? '') ??
          defaultTrialDays,
    );
  }

  final String id;
  final String name;
  final String price;
  /// `monthly` | `yearly` — sent as `plan_type` to `package/payment-create`.
  final String packageType;
  final String? appleStoreId;

  /// The offer running when the list was fetched, if any. Check
  /// [PackageOffer.isRunning] before showing or charging it.
  final PackageOffer? offer;

  /// Days of free trial a first subscription gets (`razorpay_trial_days`).
  final int trialDays;

  /// [offer] while it is still running at [now], else null.
  PackageOffer? offerAt(DateTime now) =>
      offer != null && offer!.isRunning(now) ? offer : null;

  /// What a subscription started at [now] is charged: the offer price while
  /// it runs (locked in for every renewal), else [price].
  String chargePriceAt(DateTime now) => offerAt(now)?.price ?? price;

  /// The App Store product bought at [now]: the offer's while it runs and has
  /// one, else [appleProductId].
  String appleProductIdAt(DateTime now) =>
      offerAt(now)?.appleStoreId ?? appleProductId;

  /// How much [offer] takes off [price] at [now], as a whole percent. Null
  /// when no offer runs or either price is missing.
  int? offerPercentOffAt(DateTime now) {
    final was = double.tryParse(price);
    final charged = double.tryParse(offerAt(now)?.price ?? '');
    if (was == null || charged == null || was <= 0) return null;
    final pct = ((1 - charged / was) * 100).round();
    return pct > 0 ? pct : null;
  }

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

  /// App Store product id from `apple_store_id` on `package/get-all`.
  /// Falls back to [AppConstants] when the API omits it.
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

/// A package's time-limited, locked-in price (admin > Packages > Offer). The
/// server sends it only while it runs; [endsAt] is worked out from `ends_in`
/// against this device's clock, so a wrong clock can't stretch it.
class PackageOffer {
  const PackageOffer({
    required this.price,
    required this.label,
    required this.endsAt,
    this.appleStoreId,
  });

  static PackageOffer? fromJson(Object? json, {DateTime? receivedAt}) {
    if (json is! Map) return null;
    final price = double.tryParse(json['price']?.toString() ?? '');
    final endsIn = int.tryParse(json['ends_in']?.toString() ?? '');
    if (price == null || price <= 0 || endsIn == null || endsIn <= 0) {
      return null;
    }
    final apple = json['apple_store_id']?.toString().trim();
    final label = json['label']?.toString().trim();
    return PackageOffer(
      price: json['price'].toString(),
      label: label == null || label.isEmpty || label == 'null'
          ? 'Limited offer'
          : label,
      endsAt: (receivedAt ?? DateTime.now()).add(Duration(seconds: endsIn)),
      appleStoreId: apple == null || apple.isEmpty || apple == 'null'
          ? null
          : apple,
    );
  }

  /// Charged during the offer, e.g. `25.00`.
  final String price;
  final String label;
  final DateTime endsAt;

  /// The App Store product at the offer price; null means no offer on iOS.
  final String? appleStoreId;

  bool isRunning(DateTime now) => now.isBefore(endsAt);

  /// Time left at [now]: `2d 04:12:09`, or `04:12:09` on the last day.
  String countdownAt(DateTime now) {
    final s = endsAt.difference(now).inSeconds.clamp(0, 1 << 31);
    String two(int n) => n.toString().padLeft(2, '0');
    final clock =
        '${two((s ~/ 3600) % 24)}:${two((s % 3600) ~/ 60)}:${two(s % 60)}';
    final days = s ~/ 86400;
    return days > 0 ? '${days}d $clock' : clock;
  }
}
