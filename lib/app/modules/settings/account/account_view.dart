import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/common_primary_button.dart';
import '../../../core/widgets/common_text_field.dart';
import '../widgets/gender_radio_group.dart';
import '../widgets/settings_scaffold.dart';
import 'account_controller.dart';

class AccountView extends GetView<AccountController> {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Account',
      bottom: Obx(
        () => CommonPrimaryButton(
          label: 'Save changes',
          isLoading: controller.isSaving.value,
          onPressed:
              controller.isSaving.value ? null : controller.save,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Manage your profile details. Email cannot be changed here.',
            style: AppTextStyles.body16().copyWith(
              color: AppColors.textMuted,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          const SettingsSectionLabel('Profile'),
          const SettingsFieldLabel('Full name'),
          CommonTextField(
            hintText: 'Your name',
            controller: controller.nameController,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          const SettingsFieldLabel('Email'),
          CommonTextField(
            hintText: 'Email',
            controller: controller.emailController,
            readOnly: true,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 6),
          Text(
            'Contact support if you need to change your email address.',
            style: AppTextStyles.body16().copyWith(
              color: AppColors.textWolf,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 22),
          const SettingsSectionLabel('Gender'),
          SettingsSurfaceCard(
            child: Obx(
              () => GenderRadioGroup(
                value: controller.selectedGender.value,
                onChanged: (v) => controller.selectedGender.value = v,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
