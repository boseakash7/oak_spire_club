import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/shimmer_box.dart';

/// Home's skeleton: the index card, the collection card, the movers card and
/// a strip of bottle cards, in one shimmer sweep.
class DashboardLoadingView extends StatelessWidget {
  const DashboardLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          kShellTabBodyContentTopGap,
          0,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Block(heights: [14, 128]),
            const SizedBox(height: AppSpacing.xl),
            const _Block(heights: [14, 132]),
            const SizedBox(height: AppSpacing.xl),
            const _Block(heights: [14, 196]),
            const SizedBox(height: AppSpacing.xl),
            const ShimmerBox(height: 14, width: 140, radius: 6),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 222,
              // Runs past the right edge, like the real strip.
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) =>
                    const ShimmerBox(height: 222, width: 148),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A section title bar, then a full-width card.
class _Block extends StatelessWidget {
  const _Block({required this.heights});

  final List<double> heights;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: heights[0], width: 120, radius: 6),
          const SizedBox(height: AppSpacing.sm),
          ShimmerBox(height: heights[1], width: double.infinity),
        ],
      ),
    );
  }
}
