import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_image_url.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../data/models/bluebook_model.dart';
import '../../../data/models/price_sparkline.dart';
import '../../../routes/app_routes.dart';
import '../../market/benchmark_detail_controller.dart';
import 'dashboard_bottle_row.dart';
import 'dashboard_section_header.dart';

/// "Top and worst performers": the market's biggest risers and fallers over
/// [windowDays], a few each, one card per bottle. Each row carries its price
/// line over the same window and opens the bottle; [onSeeAll] opens the full
/// lists.
class DashboardMovers extends StatelessWidget {
  const DashboardMovers({
    super.key,
    required this.gainers,
    required this.losers,
    required this.windowDays,
    required this.sparklines,
    required this.heroIds,
    required this.onSeeAll,
    required this.onOpen,
  });

  final List<BluebookModel> gainers;
  final List<BluebookModel> losers;
  final int windowDays;

  /// Price lines keyed by bottle id; a missing one draws the placeholder.
  final Map<String, PriceSparkline> sparklines;

  /// Bottles whose art may fly into the detail (each id once per page).
  final Set<String> heroIds;
  final VoidCallback? onSeeAll;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (gainers.isEmpty && losers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(
          title: 'Top and worst performers',
          subtitle: 'Market prices over the last $windowDays days',
          actionLabel: onSeeAll == null ? null : 'See all',
          onAction: onSeeAll,
        ),
        if (gainers.isNotEmpty)
          _Group(
            label: '▲ Top performers',
            color: PriceFormatter.percentColor(1),
            bottles: gainers,
            windowDays: windowDays,
            sparklines: sparklines,
            heroIds: heroIds,
            onOpen: onOpen,
          ),
        if (gainers.isNotEmpty && losers.isNotEmpty)
          const SizedBox(height: AppSpacing.md),
        if (losers.isNotEmpty)
          _Group(
            label: '▼ Worst performers',
            color: PriceFormatter.percentColor(-1),
            bottles: losers,
            windowDays: windowDays,
            sparklines: sparklines,
            heroIds: heroIds,
            onOpen: onOpen,
          ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.label,
    required this.color,
    required this.bottles,
    required this.windowDays,
    required this.sparklines,
    required this.heroIds,
    required this.onOpen,
  });

  final String label;
  final Color color;
  final List<BluebookModel> bottles;
  final int windowDays;
  final Map<String, PriceSparkline> sparklines;
  final Set<String> heroIds;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyS().copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ...DashboardBottleRow.spaced([
          for (final b in bottles)
            DashboardBottleRow(
              name: b.bottleName,
              imageUrls: [?AppImageUrl.resolve(b.image)],
              heroId: heroIds.contains(b.id) ? b.id : null,
              price: (double.tryParse(b.average ?? '') ?? 0) > 0
                  ? PriceFormatter.format(b.average)
                  : null,
              change: b.market?.changeOver(windowDays),
              caption: null,
              sparkline: sparklines[b.id],
              onTap: () {
                onOpen(b.id);
                Get.toNamed(
                  AppRoutes.benchmarkDetail,
                  arguments: BenchmarkDetailRouteArgs.mapFromBluebook(b),
                );
              },
            ),
        ]),
      ],
    );
  }
}
