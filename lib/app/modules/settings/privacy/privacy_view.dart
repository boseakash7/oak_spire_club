import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/common_primary_button.dart';
import '../../../core/widgets/common_text_field.dart';
import '../widgets/settings_scaffold.dart';
import 'privacy_controller.dart';

class PrivacyView extends GetView<PrivacyController> {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Privacy & security',
      bottom: Obx(
        () => CommonPrimaryButton(
          label: 'Update password',
          isLoading: controller.isSaving.value,
          onPressed:
              controller.isSaving.value ? null : controller.updatePassword,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Use a strong password you don’t use elsewhere. You’ll stay signed in on this device after updating.',
            style: AppTextStyles.body16().copyWith(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          const SettingsSectionLabel('Change password'),
          SettingsSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SettingsFieldLabel('Current password'),
                CommonTextField(
                  hintText: 'Current password',
                  controller: controller.currentPasswordController,
                  obscureText: true,
                  showVisibilityToggle: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                const SettingsFieldLabel('New password'),
                CommonTextField(
                  hintText: 'At least 8 characters',
                  controller: controller.newPasswordController,
                  obscureText: true,
                  showVisibilityToggle: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                const SettingsFieldLabel('Confirm new password'),
                CommonTextField(
                  hintText: 'Re-enter new password',
                  controller: controller.confirmPasswordController,
                  obscureText: true,
                  showVisibilityToggle: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => controller.updatePassword(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
