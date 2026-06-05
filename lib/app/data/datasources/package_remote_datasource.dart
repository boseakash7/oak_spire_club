import 'dart:io';

import 'package:get/get.dart';

import '../../core/constants/payment_currency.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/package_transaction_model.dart';
import '../models/razorpay_payment_create_model.dart';
import '../models/razorpay_payment_verify_model.dart';
import '../models/subscription_package_model.dart';

class PackageRemoteDataSource {
  PackageRemoteDataSource(this._client);
  final ApiClient _client;

  static const String _getAll = 'package/get-all';
  static const String _paymentCreate = 'package/payment-create';
  static const String _paymentVerify = 'package/payment-verify';
  static const String _transactionHistory = 'package/transaction-history';
  static const String _cancelSubscription = 'package/cancel-subscription';
  static const String _subscribe = 'package/subscribe';

  /// Bourboneur `PackageApi.all()` → GET `package/get-all`.
  Future<List<SubscriptionPackageModel>> getAll() async {
    final response = await _client.get(_getAll);
    final json = _client.parseEnvelope(response);
    final data = json['data'];
    if (data is! List) {
      throw ApiException('Unexpected server response.');
    }
    return data
        .whereType<Map>()
        .map(
          (e) => SubscriptionPackageModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  Future<RazorpayPaymentCreateModel> createPayment({
    required String userId,
    required String planType,
    required String amount,
    required String packageId,
    String currency = PaymentCurrency.usd,
  }) async {
    final response = await _client.post(
      _paymentCreate,
      FormData({
        'user_id': userId,
        'plan_type': planType,
        'amount': amount,
        'package_id': packageId,
        'currency': currency,
      }),
    );
    final json = _client.parseEnvelope(response);
    final data = json['data'];
    if (data is! Map) {
      throw ApiException('Unexpected server response.');
    }
    return RazorpayPaymentCreateModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<RazorpayPaymentVerifyModel> verifyPayment({
    required String localOrderId,
    required String status,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpayPlanId,
    required String message,
  }) async {
    final response = await _client.post(
      _paymentVerify,
      FormData({
        'local_order_id': localOrderId,
        'status': status,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_plan_id': razorpayPlanId,
        'message': message,
      }),
    );
    final json = _client.parseEnvelope(response);
    final data = json['data'];
    if (data is! Map) {
      throw ApiException('Unexpected server response.');
    }
    return RazorpayPaymentVerifyModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  /// POST `package/transaction-history` with `user_id`.
  Future<PackageTransactionHistoryResult> transactionHistory({
    required String userId,
  }) async {
    final json = await _client.postJson(_transactionHistory, {
      'user_id': userId,
    });
    final data = json['data'];
    if (data is! Map) {
      throw ApiException('Unexpected server response.');
    }
    return PackageTransactionHistoryResult.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  /// POST `package/cancel-subscription` with Razorpay subscription id.
  Future<String> cancelSubscription({
    required String razorpaySubscriptionId,
  }) async {
    final json = await _client.postJson(_cancelSubscription, {
      'razorpay_subscription_id': razorpaySubscriptionId,
      'cancel_at_cycle_end': 'false',
    });
    final data = json['data'];
    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return 'Subscription cancelled.';
  }

  /// Bourboneur `PackageApi.subscribe()` → POST `package/subscribe` (iOS IAP).
  Future<String> subscribeApple({
    required String userId,
    required String packageId,
    required String uniqueId,
  }) async {
    final json = await _client.postJson(_subscribe, {
      'user_id': userId,
      'package_id': packageId,
      'unique_id': uniqueId,
      'payment_method': Platform.isIOS ? 'apple_in_app' : 'razorpay',
    });
    final data = json['data'];
    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return 'Subscription activated.';
  }
}
