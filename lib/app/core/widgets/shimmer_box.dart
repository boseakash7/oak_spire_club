import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.height,
    required this.width,
    this.radius = 12,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
