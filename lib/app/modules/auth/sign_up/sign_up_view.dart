import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/common_primary_button.dart';
import '../../../core/widgets/common_text_field.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../routes/app_routes.dart';
import 'sign_up_controller.dart';

class SignUpView extends GetView<SignUpController> {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.signUpBackground,
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(35, 68, 35, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text('Welcome to', style: AppTextStyles.heading32Bold()),
                      GradientText(
                        '${AppConstants.appName}.',
                        style: AppTextStyles.heading32Bold(),
                        gradient: AppColors.goldGradient,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 294,
                        child: Text(
                          'Join the club now and get 50% off on life time subscription',
                          style: AppTextStyles.body16(),
                        ),
                      ),
                      const SizedBox(height: 21),
                      CommonTextField(
                        hintText: 'Full Name',
                        controller: controller.fullNameController,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 19),
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
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 19),
                      CommonTextField(
                        hintText: 'Confirm Password',
                        controller: controller.confirmPasswordController,
                        obscureText: true,
                        showVisibilityToggle: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => controller.onRegister(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Obx(
                            () => Checkbox(
                              value: controller.agreeToTerms.value,
                              onChanged: controller.toggleAgree,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: const BorderSide(color: AppColors.border),
                              checkColor: AppColors.black,
                              fillColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                        ? const Color(0xFFCCA230)
                                        : Colors.transparent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'I agree to terms & condition.',
                            style: AppTextStyles.body16(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => CommonPrimaryButton(
                          label: 'Register For FREE',
                          onPressed: controller.onRegister,
                          textStyle: AppTextStyles.button20Bold()
                              .copyWith(fontSize: 18),
                          isLoading: controller.isLoading.value,
                        ),
                      ),
                    ]),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(35, 16, 35, 20),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Text.rich(
                        TextSpan(
                          text: 'I already have an account.',
                          style: AppTextStyles.body16()
                              .copyWith(color: AppColors.white),
                          children: [
                            TextSpan(
                              text: ' Sign In',
                              style: AppTextStyles.body16().copyWith(
                                color: const Color(0xFFCCA230),
                                fontWeight: FontWeight.w700,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Get.toNamed(AppRoutes.signIn),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
