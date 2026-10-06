import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/collection_item_display.dart';
import '../../../data/models/collection_item_model.dart';
import '../../../data/models/price_sparkline.dart';
import '../../../routes/app_routes.dart';
import 'dashboard_bottle_row.dart';
import 'dashboard_section_header.dart';

/// "Your bottles on the move": the collection's bottles whose market price
/// moved most over [windowDays], either way, each with its price line. Each
/// row opens the bottle. Renders nothing when [movers] is empty.
class DashboardCollectionMovers extends StatelessWidget {
  const DashboardCollectionMovers({
    super.key,
    required this.movers,
    required this.windowDays,
    required this.heroIds,
    required this.onOpen,
  });

  final List<({CollectionItemModel item, PriceSparkline spark})> movers;
  final int windowDays;

  /// Bottles whose art may fly into the detail (each id once per page).
  final Set<String> heroIds;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (movers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(
          title: 'Your bottles on the move',
          subtitle: 'Your biggest market moves over the last $windowDays days',
        ),
        ...DashboardBottleRow.spaced([
          for (final m in movers) _row(m.item, m.spark),
        ]),
      ],
    );
  }

  Widget _row(CollectionItemModel item, PriceSparkline spark) {
    final id = item.bluebookBottleId!;
    final qty = item.displayQuantity;
    return DashboardBottleRow(
      name: item.lineTitle,
      imageUrls: item.resolvedImageCandidates,
      heroId: heroIds.contains(id) ? id : null,
      price: item.marketAverageLabel,
      change: spark.changePct,
      caption: qty > 1 ? '×$qty in your collection' : 'In your collection',
      sparkline: spark,
      onTap: () {
        onOpen(id);
        Get.toNamed(
          AppRoutes.benchmarkDetail,
          arguments: item.benchmarkDetailArguments(id),
        );
      },
    );
  }
}
