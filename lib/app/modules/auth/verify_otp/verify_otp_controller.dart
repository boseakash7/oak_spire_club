import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/dispose_after_detach.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/auth_navigation.dart';

class VerifyOtpController extends GetxController {
  static const int otpLength = 4;
  static const int resendCooldown = 60;

  final List<TextEditingController> digitControllers =
      List.generate(otpLength, (_) => TextEditingController());
  final List<FocusNode> focusNodes =
      List.generate(otpLength, (_) => FocusNode());

  final isLoading = false.obs;
  final isSendingOtp = false.obs;
  final isResending = false.obs;
  final resendSeconds = 0.obs;
  final statusMessage = ''.obs;

  Timer? _resendTimer;
  final _repo = Get.find<AuthRepository>();

  String get email => Get.arguments?['email'] as String? ?? '';

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed) focusNodes[0].requestFocus();
    });
    unawaited(_sendOtpInitial());
  }

  Future<void> _sendOtpInitial() async {
    isSendingOtp.value = true;
    statusMessage.value = 'Sending OTP…';
    try {
      await _repo.sendOtp(email: email);
      if (isClosed) return;
      statusMessage.value = 'OTP sent';
      _startResendTimer();
    } on ApiException catch (e) {
      if (isClosed) return;
      statusMessage.value = '';
      AppSnackbar.error(e.message);
    } catch (_) {
      if (isClosed) return;
      statusMessage.value = '';
      AppSnackbar.error('Could not send verification code.');
    } finally {
      if (!isClosed) isSendingOtp.value = false;
    }
  }

  void onDigitChanged(int index, String value) {
    if (isClosed) return;
    if (value.length == 1 && index < otpLength - 1) {
      focusNodes[index + 1].requestFocus();
    }
    if (value.length == 1 && index == otpLength - 1) {
      focusNodes[index].unfocus();
      onVerify();
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

  Future<void> onVerify() async {
    final code = _otpCode;
    if (code.length < otpLength) {
      AppSnackbar.error('Please enter the full code.');
      return;
    }

    isLoading.value = true;
    try {
      final user = await _repo.verifyOtp(email: email, otp: code);
      if (isClosed) return;
      _resendTimer?.cancel();
      unfocusSafely();
      AuthNavigation.completeSession(user);
    } on ApiException catch (e) {
      if (!isClosed) isLoading.value = false;
      AppSnackbar.error(e.message);
    } catch (_) {
      if (!isClosed) isLoading.value = false;
      AppSnackbar.error('Verification failed.');
    }
  }

  Future<void> onResend() async {
    if (resendSeconds.value > 0 || isResending.value || isSendingOtp.value) {
      return;
    }

    isResending.value = true;
    statusMessage.value = 'Sending OTP…';
    try {
      await _repo.sendOtp(email: email);
      AppSnackbar.success('Code resent to $email');
      statusMessage.value = 'OTP sent';
      _startResendTimer();
    } on ApiException catch (e) {
      statusMessage.value = '';
      AppSnackbar.error(e.message);
    } catch (_) {
      statusMessage.value = '';
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
    disposeAfterDetach([...digitControllers, ...focusNodes]);
    super.onClose();
  }
}
