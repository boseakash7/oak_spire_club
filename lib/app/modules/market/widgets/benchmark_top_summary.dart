import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/pricing_badge.dart';
import '../benchmark_detail_controller.dart';

/// Name, price with its movement and what it rests on, the low–high range,
/// rating and proof.
class BenchmarkTopSummary extends GetView<BenchmarkDetailController> {
  const BenchmarkTopSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final movementRaw = controller.priceMovementRaw;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          controller.productName,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.headingM().copyWith(
            fontSize: 22,
            height: 1.2,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) =>
                  AppTextStyles.collectionValueGradient.createShader(bounds),
              child: Text(
                controller.avgFormatted,
                style: AppTextStyles.numberL().copyWith(
                  fontSize: 26,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _MovementChip(raw: movementRaw),
            const Spacer(),
            Obx(() => PricingBadge(pricing: controller.pricing.value)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Range ${controller.lowFormatted} – ${controller.highFormatted}',
              style: AppTextStyles.bodyS().copyWith(color: AppColors.textWolf),
            ),
            _RatingChip(label: controller.ratingDisplay ?? '—'),
            if (controller.proofText?.trim().isNotEmpty == true)
              Text(
                controller.proofText!.trim(),
                style: AppTextStyles.bodyS().copyWith(
                  color: AppColors.textWolf,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MovementChip extends StatelessWidget {
  const _MovementChip({required this.raw});

  final String? raw;

  @override
  Widget build(BuildContext context) {
    final label = PriceFormatter.formatPriceMovementLabel(raw);
    if (label == '—') return const SizedBox.shrink();

    final color = PriceFormatter.priceMovementColor(raw);
    final kind = PriceFormatter.priceMovementArrowKind(raw);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (kind == 'up' || kind == 'down')
            SvgPicture.asset(
              kind == 'up' ? AppAssets.iconArrowUp : AppAssets.iconArrowDown,
              width: 10,
              height: 10,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            )
          else
            Icon(Icons.horizontal_rule, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodyS().copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 23,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.ratingChipBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppAssets.star,
            width: 8,
            height: 8,
            colorFilter: const ColorFilter.mode(
              AppColors.ratingStarMuted,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodyM().copyWith(
              color: AppColors.ratingStarMuted,
            ),
          ),
        ],
      ),
    );
  }
}
