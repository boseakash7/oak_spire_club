import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/animated_count_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/price_sparkline.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../data/models/market_models.dart';
import '../../../data/models/price_sparkline.dart';
import '../../home/home_controller.dart';
import 'dashboard_section_header.dart';

final _wholeDollars = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 0,
);

/// "Your collection": today's value, the gain against what was paid, the
/// move today (or this week), the value's line over the chart range, how
/// many bottles there are and how many are sealed or opened, and the
/// collection's move over the range beside the Oak Spire Index's. Tapping it
/// opens the Collection tab.
///
/// With no collection it invites the first bottle instead.
class DashboardCollectionCard extends StatelessWidget {
  const DashboardCollectionCard({
    super.key,
    required this.index,
    required this.onOpen,
    required this.onAddFirst,
  });

  /// The headline index, for the comparison line; null hides it.
  final MarketIndexSummary? index;
  final VoidCallback onOpen;
  final VoidCallback onAddFirst;

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();

    return Obx(() {
      final has = home.hasCollection.value;
      final Widget body;
      if (!has && home.isLoading.value) {
        body = const ShimmerScope(
          child: ShimmerBox(height: 196, width: double.infinity),
        );
      } else if (!has) {
        body = AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: AppEmptyState(
            compact: true,
            icon: Icons.liquor_rounded,
            title: 'Start your collection',
            message:
                'Add the bottles you own to see what they are worth today '
                'and how they move against the market.',
            actionLabel: 'Add your first bottle',
            onAction: onAddFirst,
          ),
        );
      } else {
        body = _ValueCard(home: home, index: index, onOpen: onOpen);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: 'Your collection',
            actionLabel: has ? 'Open' : null,
            onAction: has ? onOpen : null,
          ),
          body,
        ],
      );
    });
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.home,
    required this.index,
    required this.onOpen,
  });

  final HomeController home;
  final MarketIndexSummary? index;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final caption = AppTextStyles.bodyS().copyWith(
      fontSize: 11,
      color: AppColors.textWolf,
    );

    return AppPressable(
      onTap: onOpen,
      haptic: PressHaptic.tap,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Obx(() {
          final gain = home.unrealisedGain.value;
          final move = home.headerMoveText.value;
          final moveUp = home.headerMoveUp.value;
          final range = home.selectedChartRange.value;
          final mine = home.collectionMovedPercent.value;
          // The index has 30 / 90 / 365-day changes; 6M has no match.
          final theirs = index?.changeOver(range.lookBackDays);
          final prices = home.chartMarketPrices.toList(growable: false);
          final chart = prices.length < 2
              ? null
              : PriceSparkline(
                  prices: prices,
                  changePct: prices.first > 0
                      ? (prices.last - prices.first) / prices.first * 100
                      : null,
                );
          final showChart = chart != null || home.chartLoading.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          home.showingInvestedAsValue.value
                              ? 'Valued at cost'
                              : 'Worth today',
                          style: caption,
                        ),
                        const SizedBox(height: 2),
                        // The gold gradient Collection's value header uses.
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => AppTextStyles
                              .collectionValueGradient
                              .createShader(bounds),
                          child: AnimatedCountText(
                            value: home.collectionValue.value,
                            format: (v) =>
                                v <= 0 ? r'$ —' : _wholeDollars.format(v),
                            style: AppTextStyles.button20Bold().copyWith(
                              fontSize: 28,
                              height: 1.12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: 2,
                          children: [
                            if (gain != null)
                              Text(
                                '${home.unrealisedGainText.value} vs paid',
                                style: caption.copyWith(
                                  color: PriceFormatter.percentColor(gain),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (move.isNotEmpty)
                              Text(
                                move,
                                style: caption.copyWith(
                                  color: moveUp == null
                                      ? AppColors.textWolf
                                      : PriceFormatter.percentColor(
                                          moveUp ? 1 : -1,
                                        ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.textWolf,
                      ),
                      if (showChart) ...[
                        const SizedBox(height: 2),
                        PriceSparklineView(data: chart, width: 112, height: 44),
                        const SizedBox(height: 4),
                        Text('Value · ${range.label}', style: caption),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'Bottles',
                      value: home.totalBottleCount.value,
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'Sealed',
                      value: home.sealedBottleCount.value,
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'Opened',
                      value: home.openedBottleCount.value,
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'Rare',
                      value: home.totalRareCount.value,
                    ),
                  ),
                ],
              ),
              if (mine != null) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1, color: AppColors.cardBorder),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(range.label, style: caption),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _Compare(label: 'Your bottles', percent: mine),
                    ),
                    if (theirs != null)
                      Expanded(
                        child: _Compare(label: index!.name, percent: theirs),
                      ),
                  ],
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

/// One count on the card's stats line: the number over its label.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: AppTextStyles.bodyL().copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textCream,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyS().copyWith(
            fontSize: 11,
            color: AppColors.textWolf,
          ),
        ),
      ],
    );
  }
}

/// One side of the "your bottles vs the index" line.
class _Compare extends StatelessWidget {
  const _Compare({required this.label, required this.percent});

  final String label;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyS().copyWith(
            fontSize: 11,
            color: AppColors.textWolf,
          ),
        ),
        Text(
          PriceFormatter.percentLabel(percent),
          style: AppTextStyles.bodyL().copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: PriceFormatter.percentColor(percent),
          ),
        ),
      ],
    );
  }
}
