import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/analytics/app_analytics_controller.dart';
import '../../../core/animations/staggered_entrance.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/bottle_image.dart';
import '../../../data/models/collection_item_display.dart';
import '../../../data/models/collection_item_model.dart';
import '../../../routes/app_routes.dart';
import '../home_controller.dart';

/// "Top moved bottles": a horizontal strip of the collection's biggest
/// movers. Each card opens the bottle's detail, its art flying across.
class HomeTopMoved extends StatelessWidget {
  const HomeTopMoved({super.key, required this.home, this.trailingInset = 23});

  final HomeController home;
  final double trailingInset;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bottles = home.topMovedBottles.toList(growable: false);
      if (bottles.isEmpty) {
        return Padding(
          padding: EdgeInsets.only(right: trailingInset),
          child: const AppEmptyState(
            compact: true,
            icon: Icons.show_chart_rounded,
            title: 'No movement yet',
            message:
                'Once your bottles have tracked price history, the biggest '
                'movers show up here.',
          ),
        );
      }

      return SizedBox(
        height: 72,
        child: StaggerScope(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.only(right: trailingInset),
            itemCount: bottles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = bottles[index];
              return StaggeredEntrance(
                id: 'top-moved-${item.bluebookBottleId ?? item.id}',
                offsetY: 0.2,
                child: _TrendingCard(item: item),
              );
            },
          ),
        ),
      );
    });
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.item});

  final CollectionItemModel item;

  void _open() {
    final bottleId = item.bluebookBottleId;
    if (bottleId == null) return;
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(
        AppAnalyticsController.to.logTap('home_top_moved_open', {
          'bottle_id': bottleId,
        }),
      );
    }
    Get.toNamed(
      AppRoutes.benchmarkDetail,
      arguments: item.benchmarkDetailArguments(bottleId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = item.lineSubtitle.trim().isNotEmpty
        ? item.lineSubtitle.trim()
        : item.proofLabel;
    final movementRaw = item.priceMovementRaw;
    final changeColor = PriceFormatter.priceMovementColor(movementRaw);

    return AppPressable(
      onTap: item.bluebookBottleId == null ? null : _open,
      haptic: PressHaptic.tap,
      child: AppCard(
        width: 272,
        height: 72,
        padding: const EdgeInsets.fromLTRB(8, 8, 13, 8),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BottleImage(
                  urls: item.resolvedImageCandidates,
                  bottleId: item.bluebookBottleId,
                  cacheWidthPx: 160,
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.lineTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyL(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyS().copyWith(
                      color: AppColors.textTrendingSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    PriceFormatter.formatPriceMovementLabel(movementRaw),
                    style: AppTextStyles.bodyS().copyWith(
                      color: changeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  item.marketAverageLabel,
                  style: AppTextStyles.bodyM().copyWith(
                    color: AppColors.textCream,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
