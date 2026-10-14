import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/common_primary_button.dart';

/// Home's first card for a user who has just registered: a greeting, the
/// three steps from a first bottle to tracking it against the market, and a
/// button into the add-a-bottle flow. It goes once the first bottle is in or
/// the user closes it ([DashboardController.welcomeVisible]).
class DashboardWelcomeCard extends StatelessWidget {
  const DashboardWelcomeCard({
    super.key,
    required this.firstName,
    required this.onAdd,
    required this.onDismiss,
  });

  final String firstName;
  final VoidCallback onAdd;
  final VoidCallback onDismiss;

  static const _steps = [
    ('Add your first bottle', 'Search the market or add your own.'),
    ("See what it's worth today", null),
    ('Track it against the Oak Spire Index', null),
  ];

  @override
  Widget build(BuildContext context) {
    final heading = AppTextStyles.headingM().copyWith(
      fontSize: 20,
      height: 1.25,
      color: AppColors.textCream,
    );

    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.5)),
      ),
      child: AppCard(
        showBorder: false,
        padding: const EdgeInsets.fromLTRB(16, 12, 6, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text.rich(
                      TextSpan(
                        text: 'Welcome to the club, ',
                        children: [
                          TextSpan(
                            text: firstName,
                            style: const TextStyle(color: AppColors.goldBright),
                          ),
                        ],
                      ),
                      style: heading,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  tooltip: 'Close',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    "Three steps to know what your shelf is worth.",
                    style: AppTextStyles.bodyS().copyWith(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < _steps.length; i++)
                    _Step(
                      number: i + 1,
                      title: _steps[i].$1,
                      caption: _steps[i].$2,
                      active: i == 0,
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  CommonPrimaryButton(
                    label: 'Add your first bottle',
                    onPressed: onAdd,
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

/// One numbered step. The active one has a filled gold number and a caption.
class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.active,
    this.caption,
  });

  final int number;
  final String title;
  final String? caption;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.goldBright : null,
              border: active
                  ? null
                  : Border.all(color: AppColors.goldDeep, width: 1.5),
            ),
            child: Text(
              '$number',
              style: AppTextStyles.bodyS().copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.black : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyS().copyWith(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? AppColors.textCream : AppColors.textMuted,
                    ),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      caption!,
                      style: AppTextStyles.bodyS().copyWith(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
