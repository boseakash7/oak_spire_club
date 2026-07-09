import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_snackbar.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/auth_navigation.dart';
import '../../session/user_session_controller.dart';

class DeleteAccountController extends GetxController {
  final challengeAnswerController = TextEditingController();
  final isDeleting = false.obs;

  late final int challengeX;
  late final int challengeY;

  AuthRepository get _auth => Get.find<AuthRepository>();

  @override
  void onInit() {
    super.onInit();
    _rollChallenge();
  }

  void _rollChallenge() {
    final rng = Random();
    challengeX = rng.nextInt(10);
    challengeY = rng.nextInt(10);
  }

  void refreshChallenge() {
    _rollChallenge();
    challengeAnswerController.clear();
    update();
  }

  Future<void> deleteAccount() async {
    if (isDeleting.value) return;

    final answerText = challengeAnswerController.text.trim();
    if (answerText.isEmpty) {
      await AppSnackbar.error('Please enter the answer first.');
      return;
    }

    final answer = int.tryParse(answerText);
    if (answer == null || answer != challengeX + challengeY) {
      await AppSnackbar.error('Wrong answer. Try again.');
      challengeAnswerController.clear();
      refreshChallenge();
      return;
    }

    final user = Get.find<UserSessionController>().user.value;
    if (user == null) {
      await AppSnackbar.error('You are not signed in.');
      return;
    }

    isDeleting.value = true;
    try {
      await _auth.deleteAccount(userId: user.id);
      await AppSnackbar.success('Your account has been deleted.');
      AuthNavigation.openWelcome();
    } catch (e) {
      await AppSnackbar.error(e.toString());
    } finally {
      isDeleting.value = false;
    }
  }

  @override
  void onClose() {
    challengeAnswerController.dispose();
    super.onClose();
  }
}
