import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/animations/staggered_entrance.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/home_controller.dart';
import '../../home/widgets/home_quick_stats.dart';
import '../collection_controller.dart';
import 'collection_market_chart_card.dart';
import 'collection_portfolio_mix.dart';
import 'collection_top_priced.dart';
import 'collection_value_card.dart';

/// The Collection tab's content for a non-empty collection, top to bottom:
/// quick stats, the collection's value, the portfolio mix, the "You vs the
/// market" scoreboard and chart, then the top priced bottles and "View all
/// bottles".
/// [HomeController] owns the quick stats and chart data.
class CollectionInsights extends StatelessWidget {
  const CollectionInsights({
    super.key,
    required this.controller,
    required this.inset,
  });

  final CollectionController controller;

  /// The tab's side inset.
  final double inset;

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();

    Widget padded(Widget child) => Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: child,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideEntrance(
          child: padded(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick stats', style: AppTextStyles.bodyL()),
                const SizedBox(height: 12),
                HomeQuickStats(
                  home: home,
                  onOpen: controller.openBottles,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FadeSlideEntrance(
          index: 1,
          child: padded(CollectionValueCard(controller: controller)),
        ),
        const SizedBox(height: AppSpacing.md),
        FadeSlideEntrance(
          index: 2,
          child: padded(
            Obx(
              () => CollectionPortfolioMix(
                items: controller.items.toList(growable: false),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FadeSlideEntrance(
          index: 3,
          child: padded(const CollectionMarketChartCard()),
        ),
        const SizedBox(height: AppSpacing.xl),
        FadeSlideEntrance(
          index: 4,
          child: padded(CollectionTopPriced(controller: controller)),
        ),
      ],
    );
  }
}
