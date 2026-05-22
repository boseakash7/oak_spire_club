import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/shimmer_box.dart';

class TasteLoadingView extends StatelessWidget {
  const TasteLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(23, 104, 23, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  ShimmerBox(height: 45, width: double.infinity, radius: 9),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      ShimmerBox(height: 28, width: 92, radius: 42),
                      SizedBox(width: 10),
                      ShimmerBox(height: 28, width: 110, radius: 42),
                      SizedBox(width: 10),
                      ShimmerBox(height: 28, width: 110, radius: 42),
                    ],
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ShimmerBox(
                            height: 77,
                            width: double.infinity,
                            radius: 0,
                          ),
                          SizedBox(height: 6),
                          ShimmerBox(
                            height: 77,
                            width: double.infinity,
                            radius: 0,
                          ),
                          SizedBox(height: 6),
                          ShimmerBox(
                            height: 77,
                            width: double.infinity,
                            radius: 0,
                          ),
                          SizedBox(height: 6),
                          ShimmerBox(
                            height: 69,
                            width: double.infinity,
                            radius: 0,
                          ),
                        ],
                      ),
                    ),
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
