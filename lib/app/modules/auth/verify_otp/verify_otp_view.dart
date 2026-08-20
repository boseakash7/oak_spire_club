import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/common_primary_button.dart';
import '../../../core/widgets/gradient_text.dart';
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
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      VerifyOtpController.otpLength,
                      (i) => Padding(
                        padding: EdgeInsets.only(
                          right: i < VerifyOtpController.otpLength - 1 ? 16 : 0,
                        ),
                        child: _OtpBox(
                          controller: controller.digitControllers[i],
                          focusNode: controller.focusNodes[i],
                          index: i,
                          onChanged: (v) => controller.onDigitChanged(i, v),
                          onBackspace: () => controller.handleBackspace(i),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Obx(
                    () => CommonPrimaryButton(
                      label: 'Verify',
                      onPressed: controller.onVerify,
                      textStyle:
                          AppTextStyles.button20Bold().copyWith(fontSize: 18),
                      isLoading: controller.isLoading.value,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Obx(() {
                      final seconds = controller.resendSeconds.value;
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
        ],
      ),
    );
  }
}

class _OtpBox extends StatefulWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.index,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int index;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: AppMotion.medium,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _anim, curve: AppMotion.standard),
    );
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final focused = widget.focusNode.hasFocus;
    if (focused == _focused) return;
    _focused = focused;
    if (focused) {
      _anim.forward();
    } else {
      _anim.reverse();
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.controller.text.isNotEmpty;
    final borderColor =
        _focused ? const Color(0xFFCCA230) : AppColors.border;
    final fillColor =
        _focused ? const Color(0x1ACCA230) : AppColors.panel;

    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: _focused ? 1.8 : 1,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: const Color(0xFFCCA230).withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.backspace &&
                widget.controller.text.isEmpty) {
              widget.onBackspace();
            }
          },
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            textAlign: TextAlign.center,
            maxLength: 1,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.heading32Bold().copyWith(
              fontSize: 24,
              color: hasValue ? AppColors.white : AppColors.border,
            ),
            cursorColor: const Color(0xFFCCA230),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}
