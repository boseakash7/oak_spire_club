import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_haptics.dart';
import 'animated_pressable.dart';

/// Shared empty / no-results placeholder.
///
/// An empty screen is a moment where the user is most likely to leave, so this
/// always gives them a reason and — where one exists — a way forward.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Tighter spacing for inline slots (e.g. inside a chart box).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final showAction = actionLabel != null && onAction != null;

    return FadeSlideEntrance(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: compact ? 16 : 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 44 : 64,
              height: compact ? 44 : 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.cardSurfaceGradient,
              ),
              child: Icon(
                icon,
                size: compact ? 22 : 30,
                color: AppColors.goldRich,
              ),
            ),
            SizedBox(height: compact ? 12 : 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleS().copyWith(
                color: AppColors.textCream,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyS().copyWith(
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
            if (showAction) ...[
              SizedBox(height: compact ? 14 : 22),
              AnimatedPressable(
                onTap: () {
                  AppHaptics.tap();
                  onAction!();
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: AppColors.goldGradient,
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppTextStyles.bodyS().copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
