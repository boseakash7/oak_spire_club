import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/dispose_after_detach.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';

class ForgotPasswordController extends GetxController {
  final emailController = TextEditingController();
  final isLoading = false.obs;

  final _repo = Get.find<AuthRepository>();

  Future<void> onSubmit() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      AppSnackbar.error('Please enter your email.');
      return;
    }
    if (!Validators.isValidEmail(email)) {
      AppSnackbar.error('Please enter a valid email.');
      return;
    }

    isLoading.value = true;
    try {
      await _repo.forgetPassword(email: email);
      unfocusSafely();
      // Replace this route so its TextField is gone before reset/sign-in.
      Get.offNamed(
        AppRoutes.resetPassword,
        arguments: {'email': email},
      );
    } on ApiException catch (e) {
      if (!isClosed) isLoading.value = false;
      AppSnackbar.error(e.message);
    } catch (_) {
      if (!isClosed) isLoading.value = false;
      AppSnackbar.error('Something went wrong.');
    }
  }

  @override
  void onClose() {
    unfocusSafely();
    disposeAfterDetach([emailController]);
    super.onClose();
  }
}
