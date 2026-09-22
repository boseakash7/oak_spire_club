import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/common_primary_button.dart';
import '../../../core/widgets/common_text_field.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/otp_digit_boxes.dart';
import 'reset_password_controller.dart';

class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.signInBackground, fit: BoxFit.cover),
          SafeArea(
            child: Obx(
              () => IgnorePointer(
                ignoring: controller.isLoading.value,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(35, 24, 35, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text('Reset', style: AppTextStyles.heading32Bold()),
                      GradientText(
                        'Password.',
                        style: AppTextStyles.heading32Bold(),
                        gradient: AppColors.goldGradient,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 294,
                        child: Text(
                          controller.email.isEmpty
                              ? 'Enter the code we sent to your email and set a new password.'
                              : 'Enter the code we sent to ${controller.email} and set a new password.',
                          style: AppTextStyles.body16().copyWith(
                            color: AppColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      OtpDigitBoxes(
                        controllers: controller.digitControllers,
                        focusNodes: controller.focusNodes,
                        onChanged: controller.onDigitChanged,
                        onBackspace: controller.handleBackspace,
                      ),
                      const SizedBox(height: 24),
                      CommonTextField(
                        hintText: 'New Password',
                        controller: controller.passwordController,
                        obscureText: true,
                        showVisibilityToggle: true,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 19),
                      CommonTextField(
                        hintText: 'Confirm Password',
                        controller: controller.confirmPasswordController,
                        obscureText: true,
                        showVisibilityToggle: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => controller.onReset(),
                      ),
                      const SizedBox(height: 28),
                      Obx(
                        () => CommonPrimaryButton(
                          label: 'Reset Password',
                          onPressed: controller.onReset,
                          textStyle: AppTextStyles.button20Bold()
                              .copyWith(fontSize: 18),
                          isLoading: controller.isLoading.value,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Obx(() {
                          final seconds = controller.resendSeconds.value;
                          if (controller.isResending.value) {
                            return const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Color(0xFFCCA230),
                              ),
                            );
                          }
                          if (seconds > 0) {
                            return Text(
                              'Resend code in ${seconds}s',
                              style: AppTextStyles.body16()
                                  .copyWith(color: AppColors.textMuted),
                            );
                          }
                          return GestureDetector(
                            onTap: controller.onResend,
                            child: Text(
                              'Resend Code',
                              style: AppTextStyles.body16().copyWith(
                                color: const Color(0xFFCCA230),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
