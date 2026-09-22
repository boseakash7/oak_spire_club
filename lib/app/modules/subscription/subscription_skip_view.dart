import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_assets.dart';
import '../../core/storage/app_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_subscription_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/common_primary_button.dart';
import '../../routes/app_routes.dart';
import '../../routes/auth_navigation.dart';

/// Figma node 129:320 — skip / limited-access confirmation.
class SubscriptionSkipView extends StatelessWidget {
  const SubscriptionSkipView({super.key});

  bool get _isPostAuth {
    final args = Get.arguments;
    return args is Map &&
        args[AuthNavigation.postAuthSubscriptionArg] == true;
  }

  Future<void> _continueWithLimitedAccess() async {
    if (_isPostAuth) {
      await AppStorage.markSubscriptionOfferDismissed();
      Get.offAllNamed(AppRoutes.shell);
    } else {
      Get.close(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isPostAuth,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppAssets.subscriptionBackground,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Image.asset(AppAssets.signUpBackground, fit: BoxFit.cover),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSubscriptionTheme.skipTitleHorizontalPadding,
                        48,
                        AppSubscriptionTheme.horizontalPadding,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Are you sure you dont want',
                            style: AppTextStyles.heading32Bold().copyWith(
                              fontSize: 24,
                              height: 1.15,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            'any premium benifits?',
                            style: AppTextStyles.heading32Bold().copyWith(
                              fontSize: 24,
                              height: 1.15,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 48),
                          const _LimitationRow(
                            text: 'Access to limited amount of bottles.',
                          ),
                          const SizedBox(height: 22),
                          const _LimitationRow(
                            text: 'Only 3 bottles can be tracked.',
                          ),
                          const SizedBox(height: 22),
                          const _LimitationRow(
                            text: 'Limited access to bottle insights.',
                          ),
                          const SizedBox(height: 22),
                          const _LimitationRow(
                            text: 'No real time notification.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSubscriptionTheme.horizontalPadding,
                      0,
                      AppSubscriptionTheme.horizontalPadding,
                      12,
                    ),
                    child: CommonPrimaryButton(
                      label: 'No, I want premium',
                      onPressed: () => Get.back<void>(),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _continueWithLimitedAccess(),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: AppColors.subscriptionSkipLink.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'I am okay with limited access',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppColors.subscriptionSkipLink,
                            ),
                          ),
                        ],
                      ),
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

class _LimitationRow extends StatelessWidget {
  const _LimitationRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LimitationCrossIcon(),
        const SizedBox(width: 7),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LimitationCrossIcon extends StatelessWidget {
  const _LimitationCrossIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 34,
      height: 34,
      child: Icon(
        Icons.close_rounded,
        size: 28,
        color: AppColors.subscriptionSkipDismiss,
      ),
    );
  }
}
