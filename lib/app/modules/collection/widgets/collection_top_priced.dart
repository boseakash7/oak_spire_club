import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/analytics/app_analytics_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/common_primary_button.dart';
import '../../../data/models/collection_item_display.dart';
import '../../../data/portfolio_breakdown.dart';
import '../../../routes/app_routes.dart';
import '../collection_controller.dart';
import 'collection_bottle_row.dart';
import 'collection_quick_view.dart';

/// "Top priced bottles": the collection's priciest bottles (one bottle's
/// price, not the holding), as Collection rows that open their quick view,
/// then "View all bottles", which opens the full, sortable list.
class CollectionTopPriced extends StatelessWidget {
  const CollectionTopPriced({super.key, required this.controller});

  final CollectionController controller;

  static const int _shown = 5;

  void _openAll() {
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(AppAnalyticsController.to.logTap('collection_view_all'));
    }
    Get.toNamed(AppRoutes.collectionBottles);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.items.toList(growable: false);
      final top = PortfolioBreakdown.topPriced(items, limit: _shown);
      // Read the map here so the rows rebuild as price lines land.
      final sparks = Map.of(controller.sparklines);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (top.isNotEmpty) ...[
            Text('Top priced bottles', style: AppTextStyles.bodyL()),
            const SizedBox(height: 2),
            Text(
              'Highest market price per bottle',
              style: AppTextStyles.bodyS().copyWith(
                fontSize: 11,
                color: AppColors.textWolf,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final (i, item) in top.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              Builder(
                builder: (rowContext) => CollectionBottleRow(
                  item: item,
                  heroBottleId: item.bluebookBottleId,
                  sparkline: sparks[item.bluebookBottleId ?? ''],
                  onTap: () => showCollectionQuickView(
                    rowContext,
                    item: item,
                    controller: controller,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
          ],
          CommonPrimaryButton(
            label: 'View all bottles (${items.length})',
            onPressed: _openAll,
          ),
        ],
      );
    });
  }
}
