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
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(height: 16, width: 130, radius: 6),
                            SizedBox(height: 10),
                            ShimmerBox(height: 32, width: 180, radius: 8),
                          ],
                        ),
                      ),
                      const ShimmerBox(height: 24, width: 56, radius: 6),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: const [
                      ShimmerBox(height: 28, width: 28, radius: 8),
                      SizedBox(width: 10),
                      ShimmerBox(height: 27, width: 56, radius: 20),
                      SizedBox(width: 8),
                      ShimmerBox(height: 27, width: 72, radius: 20),
                      SizedBox(width: 8),
                      ShimmerBox(height: 27, width: 88, radius: 20),
                    ],
                  ),
                  const SizedBox(height: 22),
                  for (var i = 0; i < 5; i++) ...[
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
