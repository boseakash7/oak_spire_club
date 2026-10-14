import 'dart:async';

import 'package:get/get.dart';

import '../../data/models/plan_limits.dart';
import '../../data/repositories/package_repository.dart';
import 'user_session_controller.dart';

/// What the signed-in user's plan unlocks, for screens that lock a feature
/// on the free plan. Put once in `AppBinding` (lazy, `fenix`).
///
/// [insightsLocked]: the price range, the price history and the deal check
/// are Premium while the free plan's `insights_locked` is on (admin > Plan
/// limits). Until `package/limits` answers, a free user is treated as
/// locked ([PlanLimits.fallback]), so nothing shows and then disappears. It
/// follows [UserSessionController.user], so an upgrade unlocks at once.
class PlanAccessController extends GetxController {
  PlanAccessController(this._packageRepo);

  static PlanAccessController get to => Get.find<PlanAccessController>();

  final PackageRepository _packageRepo;

  final limits = Rx<PlanLimits>(PlanLimits.fallback);
  final insightsLocked = false.obs;

  Worker? _userWorker;

  @override
  void onInit() {
    super.onInit();
    _apply();
    if (Get.isRegistered<UserSessionController>()) {
      _userWorker = ever(
        Get.find<UserSessionController>().user,
        (_) => _apply(),
      );
    }
    unawaited(refreshLimits());
  }

  @override
  void onClose() {
    _userWorker?.dispose();
    super.onClose();
  }

  /// Re-reads the plan limits (cached for an hour by the repository).
  Future<void> refreshLimits() async {
    limits.value = await _packageRepo.limits();
    _apply();
  }

  bool get _hasPremium =>
      Get.isRegistered<UserSessionController>() &&
      Get.find<UserSessionController>().user.value?.hasPremium == true;

  void _apply() {
    insightsLocked.value = limits.value.free.insightsLocked && !_hasPremium;
  }
}
