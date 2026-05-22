import 'package:flutter/material.dart';

import '../animations/app_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Horizontal filter chip (Collection / Market category rows).
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(42),
        child: AnimatedContainer(
          duration: AppMotion.chip,
          curve: AppMotion.standard,
          height: 28,
          constraints: const BoxConstraints(minWidth: 92),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(42),
            gradient: selected
                ? AppColors.goldGradient
                : AppColors.cardSurfaceGradient,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.gold1.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.chip,
            curve: AppMotion.standard,
            style: AppTextStyles.body16().copyWith(
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              color: selected ? AppColors.black : AppColors.textCream,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
