import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/show_app_dialog.dart';
import '../market_controller.dart';

/// "Sort: Name" pill over the market list. Opens a sheet of [MarketSort]s.
/// A keyword search is ranked by relevance, so the pill is hidden while one
/// is active.
class MarketSortButton extends GetView<MarketController> {
  const MarketSortButton({super.key});

  Future<void> _open(BuildContext context) async {
    final picked = await showAppAnimatedBottomSheet<MarketSort>(
      context: context,
      builder: (ctx) => _SortSheet(selected: controller.sort.value),
    );
    if (picked != null) controller.setSort(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.keyword.value.trim().isNotEmpty) {
        return const SizedBox.shrink();
      }
      final sort = controller.sort.value;
      return AppPressable(
        onTap: () => _open(context),
        haptic: PressHaptic.tap,
        semanticLabel: 'Sort bottles',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceChip,
            borderRadius: BorderRadius.circular(AppRadii.chip),
            border: Border.all(
              color: sort == MarketSort.name
                  ? AppColors.tagInactiveBorder
                  : AppColors.tagGoldBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.swap_vert_rounded,
                size: 15,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                'Sort: ${sort.label}',
                style: AppTextStyles.bodyS().copyWith(
                  color: sort == MarketSort.name
                      ? AppColors.textMuted
                      : AppColors.goldBright,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.selected});

  final MarketSort selected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.cardSurfaceGradient,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.lg,
          AppSpacing.gutter,
          AppSpacing.md + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sort bottles',
              style: AppTextStyles.titleS().copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final s in MarketSort.values)
              InkWell(
                onTap: () => Navigator.of(context).pop(s),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: s == selected
                        ? AppColors.menuRowSelected
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.label,
                          style: AppTextStyles.bodyL().copyWith(
                            color: AppColors.textCream,
                          ),
                        ),
                      ),
                      if (s == selected)
                        const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppColors.goldBright,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
