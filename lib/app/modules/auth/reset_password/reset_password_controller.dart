import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/dispose_after_detach.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';

class ResetPasswordController extends GetxController {
  static const int otpLength = 4;
  static const int resendCooldown = 60;

  final List<TextEditingController> digitControllers =
      List.generate(otpLength, (_) => TextEditingController());
  final List<FocusNode> focusNodes =
      List.generate(otpLength, (_) => FocusNode());

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;
  final isResending = false.obs;
  final resendSeconds = 0.obs;

  Timer? _resendTimer;
  final _repo = Get.find<AuthRepository>();

  String get email => Get.arguments?['email'] as String? ?? '';

  @override
  void onInit() {
    super.onInit();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed) focusNodes[0].requestFocus();
    });
  }

  void onDigitChanged(int index, String value) {
    if (isClosed) return;
    if (value.length == 1 && index < otpLength - 1) {
      focusNodes[index + 1].requestFocus();
    }
    if (value.length == 1 && index == otpLength - 1) {
      focusNodes[index].unfocus();
    }
  }

  void handleBackspace(int index) {
    if (isClosed) return;
    if (index > 0 && digitControllers[index].text.isEmpty) {
      digitControllers[index - 1].clear();
      focusNodes[index - 1].requestFocus();
    }
  }

  String get _otpCode => digitControllers.map((c) => c.text).join();

  Future<void> onReset() async {
    final code = _otpCode;
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    if (code.length < otpLength) {
      AppSnackbar.error('Please enter the full code.');
      return;
    }
    if (!Validators.isValidPassword(password)) {
      AppSnackbar.error('Password must be at least 8 characters.');
      return;
    }
    if (password != confirm) {
      AppSnackbar.error('Passwords do not match.');
      return;
    }

    isLoading.value = true;
    try {
      await _repo.resetPassword(
        email: email,
        otp: code,
        password: password,
      );
      if (isClosed) return;

      AppSnackbar.success('Password updated. Please sign in.');
      _resendTimer?.cancel();
      unfocusSafely();
      for (final node in focusNodes) {
        if (node.hasFocus) node.unfocus();
      }

      // Wait for TextFields to detach before clearing the navigator stack.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (isClosed) return;
      Get.offAllNamed(AppRoutes.signIn);
    } on ApiException catch (e) {
      if (!isClosed) isLoading.value = false;
      AppSnackbar.error(e.message);
    } catch (_) {
      if (!isClosed) isLoading.value = false;
      AppSnackbar.error('Could not reset password.');
    }
  }

  Future<void> onResend() async {
    if (resendSeconds.value > 0 || isResending.value) return;

    isResending.value = true;
    try {
      await _repo.forgetPassword(email: email);
      AppSnackbar.success('Code resent to $email');
      _startResendTimer();
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Could not resend code.');
    } finally {
      if (!isClosed) isResending.value = false;
    }
  }

  void _startResendTimer() {
    resendSeconds.value = resendCooldown;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (isClosed) {
        t.cancel();
        return;
      }
      if (resendSeconds.value <= 1) {
        t.cancel();
        resendSeconds.value = 0;
      } else {
        resendSeconds.value--;
      }
    });
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    unfocusSafely();
    disposeAfterDetach([
      ...digitControllers,
      ...focusNodes,
      passwordController,
      confirmPasswordController,
    ]);
    super.onClose();
  }
}
