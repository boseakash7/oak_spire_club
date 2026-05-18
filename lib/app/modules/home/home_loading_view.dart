import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/shimmer_box.dart';

class HomeLoadingView extends StatelessWidget {
  const HomeLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF080405), Color(0xFF080405)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                23,
                kShellTabBodyContentTopGap,
                23,
                90,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(height: 22, width: 170, radius: 6),
                  const SizedBox(height: 12),
                  const ShimmerBox(height: 44, width: 220, radius: 8),
                  const SizedBox(height: 10),
                  const ShimmerBox(height: 16, width: 240, radius: 6),
                  const SizedBox(height: 38),
                  Row(
                    children: const [
                      ShimmerBox(height: 16, width: 140, radius: 6),
                      Spacer(),
                      ShimmerBox(height: 18, width: 18, radius: 6),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 68,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 2,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        return const ShimmerBox(
                          height: 68,
                          width: 262,
                          radius: 16,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: const [
                      ShimmerBox(height: 16, width: 100, radius: 6),
                      Spacer(),
                      ShimmerBox(height: 18, width: 18, radius: 6),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        return const ShimmerBox(
                          height: 100,
                          width: 100,
                          radius: 16,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 26),
                  const ShimmerBox(height: 216, width: double.infinity, radius: 16),
                  const SizedBox(height: 10),
                  Container(
                    height: 1,
                    color: AppColors.gold1.withValues(alpha: 0.08),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

