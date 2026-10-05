import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// A small outlined tag on a bottle row (`12 yr`, `45%`, `Rare`). [gold] marks
/// the ones worth noticing: rare and allocated bottles.
class BottleMetaChip extends StatelessWidget {
  const BottleMetaChip({super.key, required this.label, this.gold = false});

  final String label;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: gold ? AppColors.goldAccentGlow : AppColors.surfaceChip,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(
          color: gold ? AppColors.tagGoldBorder : AppColors.tagInactiveBorder,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyS().copyWith(
          fontSize: 10,
          color: gold ? AppColors.goldRich : AppColors.textMuted,
        ),
      ),
    );
  }
}
