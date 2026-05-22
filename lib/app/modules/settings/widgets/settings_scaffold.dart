import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/gradient_text.dart';

const Color kSettingsCardBorder = Color(0xFF4A342E);

/// Full-screen settings page shell matching app dark + gold styling.
class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    super.key,
    required this.title,
    required this.child,
    this.bottom,
  });

  final String title;
  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDeep,
      body: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(color: AppColors.overlayBlack20),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      AppBackButton(onPressed: () => Get.back<void>()),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GradientText(
                          title,
                          style: AppTextStyles.heading32Bold().copyWith(
                            fontSize: 22,
                            height: 1.0,
                          ),
                          gradient: AppColors.goldGradient,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(23, 16, 23, 24),
                    child: child,
                  ),
                ),
                if (bottom != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      23,
                      0,
                      23,
                      16 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: bottom!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.body16().copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.05,
          color: AppColors.gold2,
        ),
      ),
    );
  }
}

class SettingsSurfaceCard extends StatelessWidget {
  const SettingsSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSettingsCardBorder),
        gradient: AppColors.cardSurfaceGradient,
      ),
      child: child,
    );
  }
}

class SettingsFieldLabel extends StatelessWidget {
  const SettingsFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.body16().copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textCream,
        ),
      ),
    );
  }
}
