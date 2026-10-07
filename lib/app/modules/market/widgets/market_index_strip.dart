import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/analytics/app_analytics_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/price_sparkline.dart';
import '../../../data/models/market_models.dart';
import '../../../data/models/price_sparkline.dart';
import '../../../routes/app_routes.dart';
import '../market_controller.dart';

final _indexValue = NumberFormat('#,##0.0', 'en_US');

/// The Oak Spire indexes at the top of Market: one full-width card when there
/// is a single index, else a horizontal strip, headline first. Each opens the
/// index's detail. Absent when the server has no index values yet.
class MarketIndexStrip extends GetView<MarketController> {
  const MarketIndexStrip({super.key, required this.inset});

  /// The tab's side inset; the strip scrolls past the right edge.
  final double inset;

  static const double _cardWidth = 196;
  static const double _height = 128;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = controller.indexes.isNotEmpty
          ? controller.indexes.toList(growable: false)
          : [?controller.overview.value?.index];
      if (list.isEmpty) return const SizedBox.shrink();

      if (list.length == 1) {
        return Padding(
          padding: EdgeInsets.fromLTRB(inset, 0, inset, AppSpacing.lg),
          child: SizedBox(
            height: _height,
            child: MarketIndexCard(index: list.first, wide: true),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: SizedBox(
          height: _height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: inset),
            itemCount: list.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) => SizedBox(
              width: i == 0 ? _cardWidth + 40 : _cardWidth,
              child: MarketIndexCard(index: list[i], wide: i == 0),
            ),
          ),
        ),
      );
    });
  }
}

/// One index: name, level, today's and 30-day change, and its recent line.
///
/// With a [footer] the card sizes to its content instead of filling a fixed
/// height, so it can sit in a list (Home's market card).
class MarketIndexCard extends StatelessWidget {
  const MarketIndexCard({
    super.key,
    required this.index,
    this.wide = false,
    this.title,
    this.footer,
  });

  final MarketIndexSummary index;

  /// The headline card: larger number, longer sparkline.
  final bool wide;

  /// Replaces the index name on the card's top line; the name then leads
  /// the bottle count instead.
  final String? title;

  /// Shown under a divider at the bottom of the card.
  final Widget? footer;

  void _open() {
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(
        AppAnalyticsController.to.logTap('market_index_open', {
          'slug': index.slug,
        }),
      );
    }
    Get.toNamed(
      AppRoutes.marketIndex,
      arguments: {'slug': index.slug, 'name': index.name},
    );
  }

  @override
  Widget build(BuildContext context) {
    final values = [for (final p in index.series) p.value];
    final spark = values.length < 2
        ? null
        : PriceSparkline(
            prices: values,
            changePct: values.first > 0
                ? (values.last - values.first) / values.first * 100
                : null,
          );
    final day = index.change1d;
    final month = index.change30d;
    final caption = AppTextStyles.bodyS().copyWith(
      fontSize: 11,
      color: AppColors.textWolf,
    );

    return AppPressable(
      onTap: _open,
      haptic: PressHaptic.tap,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          mainAxisSize: footer == null ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title ?? index.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyS().copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.textWolf,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _indexValue.format(index.value),
                  style: AppTextStyles.headingM().copyWith(
                    fontSize: wide ? 24 : 20,
                    height: 1.1,
                    color: AppColors.textCream,
                  ),
                ),
                const SizedBox(width: 8),
                if (day != null)
                  Text(
                    '${PriceFormatter.percentLabel(day)} today',
                    style: AppTextStyles.bodyS().copyWith(
                      fontWeight: FontWeight.w600,
                      color: PriceFormatter.percentColor(day),
                    ),
                  ),
              ],
            ),
            if (footer == null)
              const Spacer()
            else
              const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (month != null)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '30d ', style: caption),
                              TextSpan(
                                text: PriceFormatter.percentLabel(month),
                                style: caption.copyWith(
                                  color: PriceFormatter.percentColor(month),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        [
                          if (title != null) index.name,
                          index.stale
                              ? 'Not updated recently'
                              : '${NumberFormat.decimalPattern('en_US').format(index.constituents)} bottles',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: caption,
                      ),
                    ],
                  ),
                ),
                PriceSparklineView(
                  data: spark,
                  width: wide ? 96 : 64,
                  height: wide ? 32 : 24,
                ),
              ],
            ),
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: AppSpacing.sm),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
