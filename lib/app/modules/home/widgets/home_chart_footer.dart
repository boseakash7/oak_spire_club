import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/analytics/app_analytics_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../home_controller.dart';

/// Figma home — range chips + add to collection below chart legend.
class HomeChartFooter extends StatelessWidget {
  const HomeChartFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Obx(
            () => Row(
              children: [
                for (var i = 0; i < HomeChartRange.values.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  _RangeChip(
                    range: HomeChartRange.values[i],
                    selected:
                        home.selectedChartRange.value ==
                        HomeChartRange.values[i],
                    onTap: () => unawaited(
                      home.setChartRange(HomeChartRange.values[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              if (Get.isRegistered<AppAnalyticsController>()) {
                unawaited(
                  AppAnalyticsController.to.logTap('home_add_to_collection'),
                );
              }
              final res = await Get.toNamed(AppRoutes.tasteBottles);
              if (res == true) {
                await home.forceReload();
              }
            },
            child: Container(
              height: 33,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: AppColors.goldGradient,
              ),
              child: Text(
                '+ Add to collection',
                style: AppTextStyles.body16().copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.range,
    required this.selected,
    required this.onTap,
  });

  final HomeChartRange range;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 33,
        height: 33,
        decoration: BoxDecoration(
          color: selected ? AppColors.gold2 : AppColors.surfaceChip,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? AppColors.tagGoldBorder
                : AppColors.tagInactiveBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          range.label,
          style: AppTextStyles.body16().copyWith(
            fontSize: 13,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
