import 'dart:async';

import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/limit_exceeded_exception.dart';
import '../../core/storage/app_storage.dart';
import '../../core/utils/app_snackbar.dart';
import '../../data/models/package_transaction_model.dart';
import '../../data/models/subscription_package_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/package_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../session/user_session_controller.dart';

enum SubscriptionScreenMode {
  /// Default IAP / plan picker for users without an active plan.
  checkout,

  /// `is_free` = `1` — backend granted premium access.
  freeUser,

  /// `subscription_status` = `subscribed` — paid active subscription.
  activeSubscription,
}

class SubscriptionController extends GetxController {
  final packages = <SubscriptionPackageModel>[].obs;
  final selectedPackageId = RxnString();
  final isLoadingPackages = true.obs;
  final loadError = RxnString();

  final screenMode = SubscriptionScreenMode.checkout.obs;
  final transactionHistory = <PackageTransactionModel>[].obs;
  final isLoadingHistory = false.obs;
  final historyError = RxnString();
  final isCancelling = false.obs;
  final isBootstrapping = true.obs;

  PackageRepository get _repo => Get.find<PackageRepository>();

  UserModel? get _user => Get.find<UserSessionController>().user.value;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    isBootstrapping.value = true;
    try {
      await _refreshProfile();
      _applyScreenMode();
      await _loadForMode();
    } finally {
      isBootstrapping.value = false;
    }
  }

  Future<void> _refreshProfile() async {
    final userId = AppStorage.userId?.trim();
    if (userId == null || userId.isEmpty) return;
    if (!Get.isRegistered<UserRepository>()) return;
    try {
      await Get.find<UserRepository>().refreshUserById(userId);
    } catch (_) {
      // Keep cached session user when refresh fails.
    }
  }

  void _applyScreenMode() {
    final user = _user;
    if (user?.isFreeUser == true) {
      screenMode.value = SubscriptionScreenMode.freeUser;
      return;
    }
    if (user?.hasActiveSubscription == true) {
      screenMode.value = SubscriptionScreenMode.activeSubscription;
      return;
    }
    screenMode.value = SubscriptionScreenMode.checkout;
  }

  Future<void> _loadForMode() async {
    switch (screenMode.value) {
      case SubscriptionScreenMode.checkout:
        await loadPackages();
      case SubscriptionScreenMode.freeUser:
        isLoadingPackages.value = false;
      case SubscriptionScreenMode.activeSubscription:
        isLoadingPackages.value = false;
        await loadTransactionHistory();
    }
  }

  Future<void> reload() async {
    isBootstrapping.value = true;
    try {
      await _refreshProfile();
      _applyScreenMode();
      await _loadForMode();
    } finally {
      isBootstrapping.value = false;
    }
  }

  Future<void> loadPackages() async {
    isLoadingPackages.value = true;
    loadError.value = null;
    try {
      final list = await _repo.getAll();
      list.sort((a, b) {
        if (a.isYearly == b.isYearly) {
          return a.displayPriceInt.compareTo(b.displayPriceInt);
        }
        return a.isYearly ? 1 : -1;
      });
      packages.assignAll(list);
      if (list.isEmpty) {
        selectedPackageId.value = null;
      } else if (selectedPackageId.value == null ||
          !list.any((p) => p.id == selectedPackageId.value)) {
        final monthly = list.where((p) => !p.isYearly).toList();
        selectedPackageId.value =
            monthly.isNotEmpty ? monthly.first.id : list.first.id;
      }
    } on LimitExceededException {
      packages.clear();
      selectedPackageId.value = null;
    } on ApiException catch (e) {
      packages.clear();
      selectedPackageId.value = null;
      loadError.value = e.message;
    } catch (e) {
      packages.clear();
      selectedPackageId.value = null;
      loadError.value = e.toString();
    } finally {
      isLoadingPackages.value = false;
    }
  }

  Future<void> loadTransactionHistory() async {
    final userId = AppStorage.userId?.trim();
    if (userId == null || userId.isEmpty) {
      historyError.value = 'Please sign in again.';
      return;
    }

    isLoadingHistory.value = true;
    historyError.value = null;
    try {
      final result = await _repo.transactionHistory(userId: userId);
      transactionHistory.assignAll(result.history);
    } on ApiException catch (e) {
      transactionHistory.clear();
      historyError.value = e.message;
    } catch (e) {
      transactionHistory.clear();
      historyError.value = e.toString();
    } finally {
      isLoadingHistory.value = false;
    }
  }

  /// `razorpay_subscription_id` from [transactionHistory] for cancel API.
  String? get razorpaySubscriptionIdForCancel =>
      transactionHistory.resolveRazorpaySubscriptionIdForCancel();

  bool get isAppleSubscriber {
    final method = _user?.lastPaymentMethod?.trim().toLowerCase();
    return method == 'apple_in_app';
  }

  bool get canCancelSubscription =>
      !isAppleSubscriber && razorpaySubscriptionIdForCancel != null;

  bool get canManageAppleSubscription => isAppleSubscriber;

  Future<void> cancelSubscription() async {
    var razorpaySubscriptionId = razorpaySubscriptionIdForCancel;
    if (razorpaySubscriptionId == null) {
      await loadTransactionHistory();
      razorpaySubscriptionId = razorpaySubscriptionIdForCancel;
    }
    if (razorpaySubscriptionId == null) {
      await AppSnackbar.error(
        'No subscription id found. Please try again after history loads.',
      );
      return;
    }

    isCancelling.value = true;
    try {
      final message = await _repo.cancelSubscription(
        razorpaySubscriptionId: razorpaySubscriptionId,
      );
      await _refreshProfile();
      _applyScreenMode();
      if (screenMode.value == SubscriptionScreenMode.checkout) {
        await loadPackages();
      } else {
        await loadTransactionHistory();
      }
      await AppSnackbar.success(message);
    } on ApiException catch (e) {
      await AppSnackbar.error(e.message);
    } catch (e) {
      await AppSnackbar.error(e.toString());
    } finally {
      isCancelling.value = false;
    }
  }

  SubscriptionPackageModel? get selectedPackage {
    final id = selectedPackageId.value;
    if (id == null) return null;
    for (final p in packages) {
      if (p.id == id) return p;
    }
    return null;
  }

  void selectPackage(String id) => selectedPackageId.value = id;

  bool get showCheckout => screenMode.value == SubscriptionScreenMode.checkout;
  bool get showFreeUser => screenMode.value == SubscriptionScreenMode.freeUser;
  bool get showActiveSubscription =>
      screenMode.value == SubscriptionScreenMode.activeSubscription;
}
