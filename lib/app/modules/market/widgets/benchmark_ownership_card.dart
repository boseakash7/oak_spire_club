import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/animated_fill_bar.dart';
import '../../../core/widgets/app_card.dart';
import '../benchmark_detail_controller.dart';

/// "You have this": what the user paid, how many, the gain, and how full.
/// Slides in once ownership has loaded; absent when the bottle is not owned.
class BenchmarkOwnershipCard extends GetView<BenchmarkDetailController> {
  const BenchmarkOwnershipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.hasInCollection.value) return const SizedBox.shrink();

      final gain = controller.collectionGainDollars.value;
      final movementRaw = controller.collectionPriceMovementRaw.value;
      final movementLabel = PriceFormatter.formatPriceMovementLabel(
        movementRaw,
      );

      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 18,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'You have this',
                    style: AppTextStyles.titleS().copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '× ${controller.collectionQuantity.value}',
                    style: AppTextStyles.bodyM().copyWith(
                      color: AppColors.textCream,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Bought at',
                    style: AppTextStyles.bodyS().copyWith(
                      color: AppColors.textOwnedLabel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    controller.collectionPaidLabel.value,
                    style: AppTextStyles.bodyM().copyWith(
                      color: AppColors.textCream,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (gain != null)
                    Text(
                      '${gain >= 0 ? '+' : '−'}'
                      '${PriceFormatter.format(gain.abs().round().toString())}',
                      style: AppTextStyles.bodyM().copyWith(
                        color: gain >= 0
                            ? AppColors.trendPositive
                            : AppColors.marketTrendDown,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (movementLabel != '—') ...[
                    const SizedBox(width: 4),
                    Text(
                      '($movementLabel)',
                      style: AppTextStyles.bodyS().copyWith(
                        color: PriceFormatter.priceMovementColor(movementRaw),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Fill',
                    style: AppTextStyles.bodyS().copyWith(
                      color: AppColors.textOwnedLabel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedFillBar(
                      value: controller.collectionFillRatio.value,
                      height: 8,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(controller.collectionFillRatio.value * 100).round()}%',
                    style: AppTextStyles.bodyS().copyWith(
                      color: AppColors.textCream,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
