import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/firebase/firebase_notification_topics.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/app_snackbar.dart';
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
  final resendSeconds = 0.obs;

  Timer? _resendTimer;
  final _repo = Get.find<AuthRepository>();

  String get email => Get.arguments?['email'] as String? ?? '';
  String get _fullName => Get.arguments?['fullName'] as String? ?? '';
  String get _password => Get.arguments?['password'] as String? ?? '';

  @override
  void onInit() {
    super.onInit();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNodes[0].requestFocus();
    });
  }

  void onDigitChanged(int index, String value) {
    if (value.length == 1 && index < otpLength - 1) {
      focusNodes[index + 1].requestFocus();
    }
    if (value.length == 1 && index == otpLength - 1) {
      focusNodes[index].unfocus();
      onVerify();
    }
  }

  bool handleBackspace(int index) {
    if (index > 0 && digitControllers[index].text.isEmpty) {
      digitControllers[index - 1].clear();
      focusNodes[index - 1].requestFocus();
      return true;
    }
    return false;
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
      await _repo.verifyOtp(email: email, otp: code);
      final user = await _repo.register(
        fullName: _fullName,
        email: email,
        password: _password,
      );
      await FirebaseNotificationTopics.syncNewRegistrationTopic();
      AuthNavigation.completeSession(user);
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Verification failed.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onResend() async {
    if (resendSeconds.value > 0) return;

    try {
      await _repo.sendOtp(email: email);
      AppSnackbar.success('Code resent to $email');
      _startResendTimer();
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Could not resend code.');
    }
  }

  void _startResendTimer() {
    resendSeconds.value = resendCooldown;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
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
    for (final c in digitControllers) {
      c.dispose();
    }
    for (final n in focusNodes) {
      n.dispose();
    }
    super.onClose();
  }
}
