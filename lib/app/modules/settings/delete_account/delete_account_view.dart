import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/common_text_field.dart';
import '../widgets/settings_scaffold.dart';
import 'delete_account_controller.dart';

class DeleteAccountView extends GetView<DeleteAccountController> {
  const DeleteAccountView({super.key});

  static const Color _kDanger = Color(0xFFB3261E);

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Delete account',
      bottom: Obx(
        () => SizedBox(
          height: 56,
          width: double.infinity,
          child: Material(
            color: _kDanger,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: controller.isDeleting.value
                  ? null
                  : controller.deleteAccount,
              child: Center(
                child: controller.isDeleting.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Delete my account',
                        style: AppTextStyles.body16().copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
      child: GetBuilder<DeleteAccountController>(
        builder: (c) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kDanger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _kDanger.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                '!! Caution !!\nOnly if you’re 100% certain.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body16().copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'We’re sorry to see you go. If you’d like to share feedback, email '
              '${AppConstants.supportEmail}.\n\n'
              'Deleting your ${AppConstants.appName} account permanently removes '
              'your profile, collection, and all associated data. You will not '
              'be able to sign in again or recover this information. To use the '
              'app again, you’ll need to create a new account.',
              style: AppTextStyles.body16().copyWith(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            const SettingsSectionLabel('Confirm'),
            SettingsSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsFieldLabel(
                    'What is ${c.challengeX} + ${c.challengeY}?',
                  ),
                  CommonTextField(
                    hintText: 'Enter the sum',
                    controller: c.challengeAnswerController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => c.deleteAccount(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
