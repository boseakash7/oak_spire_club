import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/analytics/app_analytics_controller.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_segmented_range.dart';
import '../../../data/models/collection_item_model.dart';
import '../../../data/portfolio_breakdown.dart';

final _wholeDollars = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 0,
);

/// "Portfolio mix": how the collection's value splits across spirit types
/// or brands, as one stacked bar and a legend with each slice's value and
/// share. Titled inside the card, like Market's index cards.
class CollectionPortfolioMix extends StatefulWidget {
  const CollectionPortfolioMix({super.key, required this.items});

  final List<CollectionItemModel> items;

  @override
  State<CollectionPortfolioMix> createState() => _CollectionPortfolioMixState();
}

class _CollectionPortfolioMixState extends State<CollectionPortfolioMix> {
  PortfolioGrouping _by = PortfolioGrouping.type;

  void _select(PortfolioGrouping value) {
    if (_by == value) return;
    setState(() => _by = value);
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(
        AppAnalyticsController.to.logTap('collection_mix_toggle', {
          'by': value.name,
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slices = PortfolioBreakdown.of(widget.items, by: _by);
    if (slices.isEmpty) return const SizedBox.shrink();

    final caption = AppTextStyles.bodyS().copyWith(
      fontSize: 11,
      color: AppColors.textWolf,
    );

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio mix',
                      style: AppTextStyles.bodyS().copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Share of today\'s value', style: caption),
                  ],
                ),
              ),
              AppSegmentedRange<PortfolioGrouping>(
                values: PortfolioGrouping.values,
                selected: _by,
                segmentWidth: 56,
                height: 30,
                labelOf: (g) => g.label,
                onChanged: _select,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.stateSwitch),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            child: Column(
              key: ValueKey(_by),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Bar(slices: slices),
                const SizedBox(height: AppSpacing.sm),
                for (final (i, s) in slices.indexed)
                  _LegendRow(slice: s, color: _colorOf(s, i)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _colorOf(PortfolioSlice slice, int index) =>
    slice.isOther || index >= AppColors.portfolioMix.length
    ? AppColors.portfolioMixOther
    : AppColors.portfolioMix[index];

/// The slices end to end, each as wide as its share.
class _Bar extends StatelessWidget {
  const _Bar({required this.slices});

  final List<PortfolioSlice> slices;

  /// A sliver of a share still shows as a sliver.
  static const double _minFlex = 0.015;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 10,
        // Stretch: a childless ColoredBox is otherwise zero tall.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, s) in slices.indexed) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                flex: (s.share.clamp(_minFlex, 1) * 1000).round(),
                child: ColoredBox(color: _colorOf(s, i)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A slice's swatch, name and bottle count, then its value and share.
class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.slice, required this.color});

  final PortfolioSlice slice;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final caption = AppTextStyles.bodyS().copyWith(
      fontSize: 11,
      color: AppColors.textWolf,
    );
    final pct = slice.share * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: slice.label,
                    style: AppTextStyles.bodyM().copyWith(
                      color: AppColors.textCream,
                    ),
                  ),
                  TextSpan(
                    text:
                        '  ${slice.bottles} '
                        '${slice.bottles == 1 ? 'bottle' : 'bottles'}',
                    style: caption,
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(_wholeDollars.format(slice.value), style: caption),
          SizedBox(
            width: 48,
            child: Text(
              pct >= 10 || pct == 0
                  ? '${pct.round()}%'
                  : pct < 1
                  ? '<1%'
                  : '${pct.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyM().copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textCream,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
