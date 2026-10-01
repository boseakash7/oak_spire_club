import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/analytics/app_analytics_controller.dart';
import '../../../core/widgets/app_add_pill.dart';
import '../../../core/widgets/app_segmented_range.dart';
import '../../../routes/app_routes.dart';
import '../home_controller.dart';

/// Below the home chart: the range selector and "Add to collection".
class HomeChartFooter extends StatelessWidget {
  const HomeChartFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Obx(
            () => AppSegmentedRange<HomeChartRange>(
              values: HomeChartRange.values,
              selected: home.selectedChartRange.value,
              labelOf: (r) => r.label,
              onChanged: (r) => unawaited(home.setChartRange(r)),
            ),
          ),
          const Spacer(),
          AppAddPill(
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
          ),
        ],
      ),
    );
  }
}
