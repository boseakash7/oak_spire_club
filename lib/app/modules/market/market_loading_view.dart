import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/shimmer_box.dart';

class MarketLoadingView extends StatelessWidget {
  const MarketLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.surfaceDeep, AppColors.surfaceDeep]),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.overlayBlack20)),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                23,
                kShellTabBodyContentTopGap,
                23,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(height: 45, width: double.infinity, radius: 9),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      ShimmerBox(height: 27, width: 78, radius: 42),
                      SizedBox(width: 8),
                      ShimmerBox(height: 27, width: 110, radius: 42),
                      SizedBox(width: 8),
                      ShimmerBox(height: 27, width: 110, radius: 42),
                    ],
                  ),
                  SizedBox(height: 14),
                  ShimmerBox(height: 16, width: 220, radius: 4),
                  SizedBox(height: 12),
                  ShimmerBox(height: 97, width: double.infinity, radius: 9),
                  SizedBox(height: 12),
                  ShimmerBox(height: 97, width: double.infinity, radius: 9),
                  SizedBox(height: 12),
                  ShimmerBox(height: 97, width: double.infinity, radius: 9),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
