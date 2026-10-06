import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/animations/staggered_entrance.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/home_controller.dart';
import '../../home/widgets/home_chart_footer.dart';
import '../../home/widgets/home_quick_stats.dart';
import '../../home/widgets/home_top_moved.dart';
import '../../home/widgets/home_value_chart.dart';

/// What used to be the Home tab, now under the Collection value header: the
/// value vs index chart, the collection's top movers and quick stats.
/// [HomeController] still owns the data; Market is the landing tab now.
class CollectionInsights extends StatelessWidget {
  const CollectionInsights({super.key, required this.inset});

  /// The tab's side inset. Horizontal strips run past the right edge and the
  /// chart bleeds to [kHomeChartHorizontalInset].
  final double inset;

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    final width = MediaQuery.sizeOf(context).width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeSlideEntrance(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kHomeChartHorizontalInset,
                ),
                child: SizedBox(
                  width: width - kHomeChartHorizontalInset * 2,
                  child: const HomeValueChart(),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: inset),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 14),
                    HomeChartLegend(),
                    HomeChartFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FadeSlideEntrance(
          index: 2,
          child: Padding(
            padding: EdgeInsets.only(left: inset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Top moved bottles', style: AppTextStyles.bodyL()),
                const SizedBox(height: 12),
                HomeTopMoved(home: home, trailingInset: inset),
                const SizedBox(height: 18),
                Text('Quick stats', style: AppTextStyles.bodyL()),
                const SizedBox(height: 12),
                HomeQuickStats(home: home),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
