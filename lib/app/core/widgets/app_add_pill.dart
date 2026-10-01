import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_pressable.dart';

/// The gold "+ Add to collection" pill (home chart footer, bottle detail).
class AppAddPill extends StatelessWidget {
  const AppAddPill({
    super.key,
    required this.onTap,
    this.label = 'Add to collection',
    this.icon = Icons.add_rounded,
  });

  final VoidCallback? onTap;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: PressHaptic.tap,
      semanticLabel: label,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          gradient: AppColors.goldGradient,
          boxShadow: const [
            BoxShadow(
              color: AppColors.goldGlow,
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.black),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption().copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
