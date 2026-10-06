import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_image_url.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../data/models/market_models.dart';
import '../../../data/models/price_sparkline.dart';
import '../../../routes/app_routes.dart';
import '../../market/benchmark_detail_controller.dart';
import 'dashboard_bottle_row.dart';
import 'dashboard_section_header.dart';

/// A Home section of bottles, one card per bottle: each has the art, name, a
/// line saying why the bottle is here ([captionOf]), and its price line with
/// that line's change (the line covers Home's 90-day window, or as much of
/// it as the bottle has prices for). Each row opens the bottle.
/// Renders nothing when [items] is empty.
class DashboardBottleList extends StatelessWidget {
  const DashboardBottleList({
    super.key,
    required this.section,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.captionOf,
    required this.sparklines,
    required this.heroIds,
    required this.onOpen,
  });

  /// Analytics key, e.g. `hot`.
  final String section;
  final String title;
  final String subtitle;
  final List<HighlightBottle> items;
  final String Function(HighlightBottle item) captionOf;
  final Map<String, PriceSparkline> sparklines;

  /// Bottles whose art may fly into the detail (each id once per page).
  final Set<String> heroIds;
  final void Function(String section, String bottleId) onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(title: title, subtitle: subtitle),
        ...DashboardBottleRow.spaced(items.map(_row)),
      ],
    );
  }

  Widget _row(HighlightBottle item) {
    final b = item.bottle;
    final priced = (double.tryParse(b.average ?? '') ?? 0) > 0;
    final spark = sparklines[b.id];
    return DashboardBottleRow(
      name: b.bottleName,
      imageUrls: [?AppImageUrl.resolve(b.image)],
      heroId: heroIds.contains(b.id) ? b.id : null,
      price: priced ? PriceFormatter.format(b.average) : null,
      change: priced ? spark?.changePct : null,
      caption: captionOf(item),
      sparkline: spark,
      onTap: () {
        onOpen(section, b.id);
        Get.toNamed(
          AppRoutes.benchmarkDetail,
          arguments: BenchmarkDetailRouteArgs.mapFromBluebook(b),
        );
      },
    );
  }
}
