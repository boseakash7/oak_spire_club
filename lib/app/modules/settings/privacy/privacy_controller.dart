import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../session/user_session_controller.dart';

class PrivacyController extends GetxController {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isSaving = false.obs;

  AuthRepository get _auth => Get.find<AuthRepository>();

  Future<void> updatePassword() async {
    final current = currentPasswordController.text;
    final newPass = newPasswordController.text;
    final confirm = confirmPasswordController.text;

    if (current.isEmpty) {
      await AppSnackbar.error('Enter your current password.');
      return;
    }
    if (!Validators.isValidPassword(newPass)) {
      await AppSnackbar.error('New password must be at least 8 characters.');
      return;
    }
    if (newPass != confirm) {
      await AppSnackbar.error('New passwords do not match.');
      return;
    }

    final user = Get.find<UserSessionController>().user.value;
    if (user == null) {
      await AppSnackbar.error('You are not signed in.');
      return;
    }

    isSaving.value = true;
    try {
      await _auth.updateProfile(
        userId: user.id,
        name: user.name?.trim() ?? '',
        oldPassword: current,
        password: newPass,
      );
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      await AppSnackbar.success('Password updated.');
      Get.back();
    } catch (e) {
      await AppSnackbar.error(e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
