import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../data/models/bottle_details.dart';
import '../benchmark_detail_controller.dart';

/// The catalog facts (distillery, type, age, ABV, cask…) as a labelled list,
/// then the description. Facts the catalog doesn't have are left out, and the
/// card is absent when there are none.
class BenchmarkFacts extends GetView<BenchmarkDetailController> {
  const BenchmarkFacts({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final facts = controller.details.value?.facts ?? const <BottleFact>[];
      final loading = controller.detailsLoading.value && facts.isEmpty;
      final body = controller.description.value?.trim() ?? '';

      return AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loading) const _FactsSkeleton(),
            if (facts.isNotEmpty) ...[
              Text(
                'About this bottle',
                style: AppTextStyles.titleS().copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < facts.length; i++)
                      _FactRow(fact: facts[i], divider: i < facts.length - 1),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Details',
              style: AppTextStyles.titleS().copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body.isNotEmpty ? body : 'No description available.',
              style: AppTextStyles.bodyM().copyWith(
                height: 1.35,
                color: body.isNotEmpty
                    ? AppColors.textNeutralSoft
                    : AppColors.textWolf,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact, required this.divider});

  final BottleFact fact;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: AppColors.cardBorder))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              fact.label,
              style: AppTextStyles.bodyS().copyWith(
                color: AppColors.textOwnedLabel,
              ),
            ),
          ),
          Expanded(
            child: Text(
              fact.value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyM().copyWith(color: AppColors.textCream),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for the facts card while the by-id request is in flight.
class _FactsSkeleton extends StatelessWidget {
  const _FactsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: ShimmerScope(
          baseColor: AppColors.shimmerOnCardBase,
          highlightColor: AppColors.shimmerOnCardHighlight,
          child: const Column(
            children: [
              _SkeletonLine(widthFactor: 0.8),
              SizedBox(height: 16),
              _SkeletonLine(widthFactor: 0.6),
              SizedBox(height: 16),
              _SkeletonLine(widthFactor: 0.7),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: const ShimmerBox(height: 12, width: double.infinity, radius: 4),
    );
  }
}
