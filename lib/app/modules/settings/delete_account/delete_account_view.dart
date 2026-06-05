import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/settings_scaffold.dart';
import 'delete_account_controller.dart';

class DeleteAccountView extends GetView<DeleteAccountController> {
  const DeleteAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Delete account',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(
            () => SizedBox(
              height: 56,
              width: double.infinity,
              child: Material(
                color: AppColors.destructive,
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
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Get.back<void>(),
            child: Text(
              'Cancel and go back',
              style: AppTextStyles.body16().copyWith(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
      child: GetBuilder<DeleteAccountController>(
        builder: (c) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'We’re sorry to see you go.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body16().copyWith(
                fontSize: 16,
                color: AppColors.white,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            const _ImportantWarningCard(),
            const SizedBox(height: 16),
            const _ContactCard(),
            const SizedBox(height: 22),
            _DeleteAccountCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _StepBadge('1'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Quick confirmation',
                          style: AppTextStyles.body16().copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Please solve the problem below to continue.',
                          style: AppTextStyles.body16().copyWith(
                            fontSize: 14,
                            color: AppColors.deleteAccountBodyText,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.deleteAccountNestedSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'What is ${c.challengeX} + ${c.challengeY}?',
                                style: AppTextStyles.body16().copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _DeleteAccountAnswerField(
                                controller: c.challengeAnswerController,
                                onSubmitted: (_) => c.deleteAccount(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class _DeleteAccountCard extends StatelessWidget {
  const _DeleteAccountCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.deleteAccountCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.deleteAccountCardBorder),
      ),
      child: child,
    );
  }
}

class _ImportantWarningCard extends StatelessWidget {
  const _ImportantWarningCard();

  @override
  Widget build(BuildContext context) {
    return _DeleteAccountCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.deleteAccountNestedSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: AppColors.gold2,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important: This action is permanent',
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Once deleted, your account, profile, and all associated '
                  'data will be permanently removed. This can’t be undone.',
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 14,
                    color: AppColors.deleteAccountBodyText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    return _DeleteAccountCard(
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.body16().copyWith(
            fontSize: 14,
            color: AppColors.deleteAccountBodyText,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: 'Before you go\n',
              style: AppTextStyles.body16().copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                height: 1.4,
              ),
            ),
            const TextSpan(
              text:
                  'If there’s anything we can help with, please contact us at ',
            ),
            TextSpan(
              text: AppConstants.supportEmail,
              style: AppTextStyles.body16().copyWith(
                fontSize: 14,
                color: AppColors.gold2,
                height: 1.4,
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountAnswerField extends StatelessWidget {
  const _DeleteAccountAnswerField({
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onSubmitted: onSubmitted,
        style: AppTextStyles.body16().copyWith(color: AppColors.white),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.deleteAccountNestedSurface,
          hintText: 'Enter your answer',
          hintStyle: AppTextStyles.body16().copyWith(
            color: AppColors.deleteAccountBodyText,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.gold2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.gold2, width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.gold2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.body16().copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.surfaceDeep,
        ),
      ),
    );
  }
}
