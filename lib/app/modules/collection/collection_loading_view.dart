import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/shimmer_box.dart';

class CollectionLoadingView extends StatelessWidget {
  const CollectionLoadingView({super.key});

  /// One shimmer sweep across the whole skeleton (see [ShimmerScope]).
  @override
  Widget build(BuildContext context) => ShimmerScope(child: _skeleton(context));

  Widget _skeleton(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surfaceDeep, AppColors.surfaceDeep],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(color: AppColors.overlayBlack20),
          ),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                23,
                kShellTabBodyContentTopGap,
                23,
                120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick stats: a two-column grid of one-line tiles.
                  const ShimmerBox(height: 16, width: 96, radius: 6),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, c) {
                      final w = (c.maxWidth - 10) / 2;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (var i = 0; i < 8; i++)
                            ShimmerBox(height: 48, width: w, radius: 12),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // The value card, the portfolio mix and the value chart.
                  for (final h in const [92.0, 168.0, 200.0]) ...[
                    LayoutBuilder(
                      builder: (context, c) => ShimmerBox(
                        height: h,
                        width: c.maxWidth,
                        radius: AppRadii.card,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  // The top priced bottles.
                  const ShimmerBox(height: 16, width: 150, radius: 6),
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    LayoutBuilder(
                      builder: (context, c) => ShimmerBox(
                        height: 104,
                        width: c.maxWidth,
                        radius: AppRadii.md,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
