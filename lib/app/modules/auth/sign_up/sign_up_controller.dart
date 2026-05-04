import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';

class SignUpController extends GetxController {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final agreeToTerms = true.obs;
  final isLoading = false.obs;

  void toggleAgree(bool? value) => agreeToTerms.value = value ?? false;

  final _repo = Get.find<AuthRepository>();

  Future<void> onRegister() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();

    if (fullName.isEmpty) {
      AppSnackbar.error('Please enter your full name.');
      return;
    }
    if (!Validators.isValidEmail(email)) {
      AppSnackbar.error('Please enter a valid email.');
      return;
    }
    if (!Validators.isValidPassword(passwordController.text)) {
      AppSnackbar.error('Password must be at least 8 characters.');
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      AppSnackbar.error('Passwords do not match.');
      return;
    }
    if (!agreeToTerms.value) {
      AppSnackbar.error('Please agree to terms & condition.');
      return;
    }

    isLoading.value = true;
    try {
      await _repo.register(
        fullName: fullName,
        email: email,
        password: passwordController.text,
      );
      Get.offAllNamed(AppRoutes.shell);
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (e, st) {
      debugPrint('Register error: $e');
      debugPrintStack(stackTrace: st);
      AppSnackbar.error('Something went wrong.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}

