import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/storage/app_storage.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../session/user_session_controller.dart';
class AccountController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final isSaving = false.obs;
  final selectedGender = RxnString();

  AuthRepository get _auth => Get.find<AuthRepository>();
  UserRepository get _users => Get.find<UserRepository>();

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  void _load() {
    final user = Get.find<UserSessionController>().user.value;
    nameController.text = user?.name?.trim() ?? '';
    emailController.text = user?.email?.trim() ?? '';
    final gender =
        user?.gender?.trim() ?? AppStorage.userGender?.trim();
    if (gender != null && gender.isNotEmpty) {
      selectedGender.value = gender;
    }
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      await AppSnackbar.error('Please enter your name.');
      return;
    }
    final gender = selectedGender.value;
    if (gender == null || gender.isEmpty) {
      await AppSnackbar.error('Please select a gender.');
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
        name: name,
        gender: gender,
      );
      await AppStorage.setUserGender(gender);
      await _users.refreshUserById(user.id);
      await AppSnackbar.success('Profile updated.');
      Get.back();
    } catch (e) {
      await AppSnackbar.error(e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }
}
