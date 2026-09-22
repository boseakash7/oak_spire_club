import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/common_primary_button.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/otp_digit_boxes.dart';
import '../../../core/widgets/otp_verify_animation.dart';
import 'verify_otp_controller.dart';

class VerifyOtpView extends GetView<VerifyOtpController> {
  const VerifyOtpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.signUpBackground, fit: BoxFit.cover),
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
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
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
                      Text('Verify Your', style: AppTextStyles.heading32Bold()),
                      GradientText(
                        'Email.',
                        style: AppTextStyles.heading32Bold(),
                        gradient: AppColors.goldGradient,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 294,
                        child: Text(
                          controller.email.isEmpty
                              ? 'Enter the 4-digit code we sent to your email.'
                              : 'Enter the 4-digit code we sent to ${controller.email}',
                          style: AppTextStyles.body16(),
                        ),
                      ),
                      Obx(() {
                        final message = controller.statusMessage.value;
                        if (message.isEmpty) {
                          return const SizedBox(height: 20);
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Row(
                            children: [
                              if (controller.isSendingOtp.value ||
                                  controller.isResending.value) ...[
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.goldAccent,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: Text(
                                  message,
                                  style: AppTextStyles.body16().copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Center(child: OtpVerifyAnimation(size: 188)),
                      const SizedBox(height: 12),
                      Obx(
                        () => OtpDigitBoxes(
                          controllers: controller.digitControllers,
                          focusNodes: controller.focusNodes,
                          onChanged: controller.onDigitChanged,
                          onBackspace: controller.handleBackspace,
                          shakeTrigger: controller.errorShake.value,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Obx(
                        () => CommonPrimaryButton(
                          label: 'Verify',
                          onPressed: controller.onVerify,
                          textStyle: AppTextStyles.button20Bold().copyWith(
                            fontSize: 18,
                          ),
                          isLoading: controller.isLoading.value,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Obx(() {
                          final seconds = controller.resendSeconds.value;
                          if (controller.isSendingOtp.value) {
                            return const SizedBox.shrink();
                          }
                          if (controller.isResending.value) {
                            return const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.goldAccent,
                              ),
                            );
                          }
                          if (seconds > 0) {
                            return Text(
                              'Resend code in ${seconds}s',
                              style: AppTextStyles.body16().copyWith(
                                color: AppColors.textMuted,
                              ),
                            );
                          }
                          return GestureDetector(
                            onTap: controller.onResend,
                            child: Text(
                              'Resend Code',
                              style: AppTextStyles.body16().copyWith(
                                color: AppColors.goldAccent,
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
