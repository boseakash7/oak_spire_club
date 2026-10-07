import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/market_models.dart';
import '../../market/widgets/market_index_strip.dart';

final _count = NumberFormat.decimalPattern('en_US');

/// "The market", one card titled inside like Market's index cards: the
/// headline Oak Spire Index (the card opens the index's page), then how many
/// market bottles rose and fell over the window, and when prices were last
/// updated. Renders nothing when there is neither an index nor a breadth.
class DashboardMarketPulse extends StatelessWidget {
  const DashboardMarketPulse({
    super.key,
    required this.index,
    required this.highlights,
    this.lastUpdated,
  });

  final MarketIndexSummary? index;
  final MarketHighlights highlights;

  /// "10.05.2026", from `market/overview`.
  final String? lastUpdated;

  @override
  Widget build(BuildContext context) {
    final index = this.index;
    if (index == null && !highlights.hasBreadth) return const SizedBox.shrink();

    final caption = AppTextStyles.bodyS().copyWith(
      fontSize: 11,
      color: AppColors.textWolf,
    );
    final breadth = highlights.hasBreadth
        ? Text.rich(
            TextSpan(
              style: caption,
              children: [
                TextSpan(
                  text: '▲ ${_count.format(highlights.rising)} rising',
                  style: caption.copyWith(
                    color: PriceFormatter.percentColor(1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '  ·  '),
                TextSpan(
                  text: '▼ ${_count.format(highlights.falling)} falling',
                  style: caption.copyWith(
                    color: PriceFormatter.percentColor(-1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: '  over ${highlights.windowDays} days'),
              ],
            ),
          )
        : null;

    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ?breadth,
        if (lastUpdated != null) ...[
          if (breadth != null) const SizedBox(height: AppSpacing.xxs),
          Text('Prices updated $lastUpdated', style: caption),
        ],
      ],
    );

    if (index != null) {
      return MarketIndexCard(
        index: index,
        wide: true,
        title: 'The market',
        footer: footer,
      );
    }

    // Breadth with no index yet: the same card, without the index.
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The market',
            style: AppTextStyles.bodyS().copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          footer,
        ],
      ),
    );
  }
}
