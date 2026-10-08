import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_image_url.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../data/models/price_sparkline.dart';
import '../../../data/models/wishlist_item.dart';
import '../../../routes/app_routes.dart';
import '../../market/benchmark_detail_controller.dart';
import '../../wishlist/widgets/wishlist_row.dart';
import 'dashboard_bottle_row.dart';
import 'dashboard_section_header.dart';

/// "Your wishlist" on Home: bottles at their target first, then the biggest
/// moves since they were added. Each row opens the bottle; "See all" opens
/// the Collection tab's Wishlist. Renders nothing when [items] is empty.
class DashboardWishlist extends StatelessWidget {
  const DashboardWishlist({
    super.key,
    required this.items,
    required this.atTargetCount,
    required this.sparklines,
    required this.heroIds,
    required this.onSeeAll,
    required this.onOpen,
  });

  final List<WishlistItem> items;
  final int atTargetCount;
  final Map<String, PriceSparkline> sparklines;

  /// Bottles whose art may fly into the detail (each id once per page).
  final Set<String> heroIds;
  final VoidCallback onSeeAll;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(
          title: 'Your wishlist',
          subtitle: atTargetCount > 0
              ? '$atTargetCount at your target price'
              : 'How their prices moved since you added them',
          actionLabel: 'See all',
          onAction: onSeeAll,
        ),
        ...DashboardBottleRow.spaced([for (final i in items) _row(i)]),
      ],
    );
  }

  Widget _row(WishlistItem item) {
    final id = item.bottleId;
    final now = item.currentPrice;
    return DashboardBottleRow(
      name: item.bottle.bottleName,
      imageUrls: [?AppImageUrl.resolve(item.bottle.image)],
      heroId: heroIds.contains(id) ? id : null,
      price: now == null ? null : PriceFormatter.format(now.round().toString()),
      change: item.changeSinceAdded,
      caption: wishlistTargetLabel(item) ?? wishlistPriceLine(item),
      sparkline: sparklines[id],
      onTap: () {
        onOpen(id);
        Get.toNamed(
          AppRoutes.benchmarkDetail,
          arguments: BenchmarkDetailRouteArgs.mapFromBluebook(item.bottle),
        );
      },
    );
  }
}
