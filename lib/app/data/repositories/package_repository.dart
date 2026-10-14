import 'package:get/get.dart';

import '../../core/cache/app_cache.dart';
import '../../core/constants/payment_currency.dart';
import '../datasources/package_remote_datasource.dart';
import '../models/package_transaction_model.dart';
import '../models/plan_limits.dart';
import '../models/razorpay_payment_create_model.dart';
import '../models/razorpay_payment_verify_model.dart';
import '../models/subscription_package_model.dart';

class PackageRepository {
  PackageRepository(this._remote);
  final PackageRemoteDataSource _remote;

  Future<List<SubscriptionPackageModel>> getAll() => _remote.getAll();

  /// The plans' limits, cached for an hour so an admin change shows up the
  /// same day. Never throws: an older server or a failed call gives
  /// [PlanLimits.fallback].
  Future<PlanLimits> limits({bool forceRefresh = false}) async {
    try {
      final raw = await Get.find<AppCache>().getOrFetch<Map<String, dynamic>>(
        cacheKey: 'package:limits',
        ttl: const Duration(hours: 1),
        forceRefresh: forceRefresh,
        fetch: _remote.limits,
        encode: (v) => v,
        decode: (json) =>
            json is Map ? Map<String, dynamic>.from(json) : const {},
      );
      return PlanLimits.fromJson(raw);
    } catch (_) {
      return PlanLimits.fallback;
    }
  }

  Future<RazorpayPaymentCreateModel> createPayment({
    required String userId,
    required String planType,
    required String amount,
    required String packageId,
    String currency = PaymentCurrency.usd,
  }) =>
      _remote.createPayment(
        userId: userId,
        planType: planType,
        amount: amount,
        packageId: packageId,
        currency: currency,
      );

  Future<RazorpayPaymentVerifyModel> verifyPayment({
    required String localOrderId,
    required String status,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpayPlanId,
    String razorpaySubscriptionId = '',
    String message = 'Payment completed from app',
  }) =>
      _remote.verifyPayment(
        localOrderId: localOrderId,
        status: status,
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpayPlanId: razorpayPlanId,
        razorpaySubscriptionId: razorpaySubscriptionId,
        message: message,
      );

  Future<PackageTransactionHistoryResult> transactionHistory({
    required String userId,
  }) =>
      _remote.transactionHistory(userId: userId);

  Future<String> cancelSubscription({
    required String razorpaySubscriptionId,
  }) =>
      _remote.cancelSubscription(
        razorpaySubscriptionId: razorpaySubscriptionId,
      );

  Future<String> subscribeApple({
    required String userId,
    required String packageId,
    required String uniqueId,
  }) =>
      _remote.subscribeApple(
        userId: userId,
        packageId: packageId,
        uniqueId: uniqueId,
      );
}
