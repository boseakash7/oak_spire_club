import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/validators.dart';

class ForgotPasswordController extends GetxController {
  final emailController = TextEditingController();
  final isLoading = false.obs;

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
      // Wire forgot-password API here when available.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      AppSnackbar.success('If an account exists, you will receive reset instructions.');
      Get.back<void>();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
