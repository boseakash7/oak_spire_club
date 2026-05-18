import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/analytics/app_analytics_controller.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/common_primary_button.dart';
import '../../../core/widgets/common_text_field.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../routes/app_routes.dart';
import 'sign_in_controller.dart';

class SignInView extends GetView<SignInController> {
  const SignInView({super.key});

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
                  Text('Sign In to', style: AppTextStyles.heading32Bold()),
                  GradientText(
                    '${AppConstants.appName}.',
                    style: AppTextStyles.heading32Bold(),
                    gradient: AppColors.goldGradient,
                  ),
                  const SizedBox(height: 40),
                  CommonTextField(
                    hintText: 'Email',
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 19),
                  CommonTextField(
                    hintText: 'Password',
                    controller: controller.passwordController,
                    obscureText: true,
                    showVisibilityToggle: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => controller.onSignIn(),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        if (Get.isRegistered<AppAnalyticsController>()) {
                          unawaited(
                            AppAnalyticsController.to
                                .logTap('sign_in_forgot_password'),
                          );
                        }
                        Get.toNamed(AppRoutes.forgotPassword);
                      },
                      child: Text(
                        'Forgot password?',
                        style: AppTextStyles.body16().copyWith(
                          color: const Color(0xFFCCA230),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFFCCA230),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(
                    () => CommonPrimaryButton(
                      label: 'Sign In',
                      onPressed: controller.onSignIn,
                      isLoading: controller.isLoading.value,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: "Don't have an account? ",
                        style: AppTextStyles.body16().copyWith(
                          color: AppColors.white,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign up',
                            style: AppTextStyles.body16().copyWith(
                              color: const Color(0xFFCCA230),
                              fontWeight: FontWeight.w700,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                if (Get.isRegistered<AppAnalyticsController>()) {
                                  unawaited(
                                    AppAnalyticsController.to
                                        .logTap('sign_in_go_sign_up'),
                                  );
                                }
                                if (Navigator.of(context).canPop()) {
                                  Get.back();
                                } else {
                                  Get.offNamed(AppRoutes.signUp);
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
