import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';

class SignInController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _repo = Get.find<AuthRepository>();
  final isLoading = false.obs;

  Future<void> onSignIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (!Validators.isValidEmail(email)) {
      AppSnackbar.error('Please enter a valid email.');
      return;
    }
    if (password.isEmpty) {
      AppSnackbar.error('Please enter your password.');
      return;
    }

    isLoading.value = true;
    try {
      await _repo.login(email: email, password: password);
      Get.offAllNamed(AppRoutes.shell);
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (e, st) {
      debugPrint('Login error: $e');
      debugPrintStack(stackTrace: st);
      AppSnackbar.error('Something went wrong.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
