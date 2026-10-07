import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// A Home section's title, an optional one-line explanation under it, and an
/// optional text action (or any [trailing] widget) on the right.
class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Shown after the action, e.g. a toggle.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyL()),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyS().copyWith(
                      fontSize: 11,
                      color: AppColors.textWolf,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: AppTextStyles.bodyS().copyWith(
                  color: AppColors.goldBright,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ?trailing,
        ],
      ),
    );
  }
}
