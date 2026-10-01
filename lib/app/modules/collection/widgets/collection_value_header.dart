import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_count_text.dart';
import '../collection_controller.dart';

final _wholeDollars = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 0,
);

/// "Collection Value" with the total counting up and the 90-day move.
class CollectionValueHeader extends StatelessWidget {
  const CollectionValueHeader({super.key, required this.controller});

  final CollectionController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Collection Value',
                style: AppTextStyles.titleL().copyWith(
                  color: AppColors.textCream,
                ),
              ),
              const SizedBox(height: 8),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) =>
                    AppTextStyles.collectionValueGradient.createShader(bounds),
                child: Obx(
                  () => AnimatedCountText(
                    value: controller.valueAmount.value,
                    format: (v) => v <= 0 ? r'$ —' : _wholeDollars.format(v),
                    style: AppTextStyles.button20Bold().copyWith(
                      fontSize: 28,
                      height: 1.12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Obx(() {
          final trend = controller.trendShort.value;
          return AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.medium),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Container(
              key: ValueKey(trend),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.goldAccentGlow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.tagGoldBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    AppAssets.collectionTrendChart,
                    width: 22,
                    height: 11,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    trend,
                    style: AppTextStyles.bodyL().copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldBright,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
