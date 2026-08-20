import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/common_primary_button.dart';
import '../../../core/widgets/common_text_field.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../routes/app_routes.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.signInBackground, fit: BoxFit.cover),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(35, 185, 35, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Forgot', style: AppTextStyles.heading32Bold()),
                  GradientText(
                    'Password?',
                    style: AppTextStyles.heading32Bold(),
                    gradient: AppColors.goldGradient,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter your email and we will send a verification code to reset your password.',
                    style: AppTextStyles.body16().copyWith(
                      color: const Color(0xFFBAB59F),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 36),
                  CommonTextField(
                    hintText: 'Email',
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => controller.onSubmit(),
                  ),
                  const SizedBox(height: 33),
                  Obx(
                    () => CommonPrimaryButton(
                      label: 'Send Code',
                      onPressed: controller.onSubmit,
                      isLoading: controller.isLoading.value,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: 'Remember password? ',
                        style: AppTextStyles.body16().copyWith(
                          color: AppColors.white,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: AppTextStyles.body16().copyWith(
                              color: const Color(0xFFCCA230),
                              fontWeight: FontWeight.w700,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                if (Navigator.of(context).canPop()) {
                                  Get.back<void>();
                                } else {
                                  Get.offNamed(AppRoutes.signIn);
                                }
                              },
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
