import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/staggered_entrance.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_count_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../data/collection_value_calculator.dart';
import '../../collection/collection_controller.dart';
import '../home_controller.dart';

final _count = NumberFormat.decimalPattern('en_US');

/// One Quick Stats tile. Modelled as data so the grid is a list, not a
/// switch over hard-coded indices.
class _QuickStat {
  const _QuickStat.count(this.label, this.icon, this.filter, int this.count)
    : ratingText = null;

  const _QuickStat.rating(
    this.label,
    this.icon,
    this.filter,
    String this.ratingText,
  ) : count = null;

  final String label;
  final IconData icon;

  /// The bottles this tile counts, shown in the list it opens.
  final CollectionFilter filter;
  final int? count;
  final String? ratingText;

  bool get isRating => ratingText != null;
}

/// "Quick Stats": collection size, bottles drunk, rating, rare finds, then
/// duplicates and how many bottles are worth more (or less) than was paid.
/// One line per tile (icon, label, number), two tiles to a row. Tapping a
/// tile calls [onOpen] with its filter, to list the bottles it counts.
class HomeQuickStats extends StatelessWidget {
  const HomeQuickStats({super.key, required this.home, required this.onOpen});

  final HomeController home;
  final ValueChanged<CollectionFilter> onOpen;

  static const double _tileHeight = 48;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Obx(() {
        final counts = CollectionValueCalculator.holdingCounts(home.items);
        final stats = [
          _QuickStat.count(
            'Collection',
            Icons.liquor_rounded,
            CollectionFilter.all,
            home.totalCollectionCount.value,
          ),
          _QuickStat.count(
            'Drunk',
            Icons.local_bar_rounded,
            CollectionFilter.drunk,
            home.totalDrunkCount.value,
          ),
          _QuickStat.rating(
            'Rating',
            Icons.star_rounded,
            CollectionFilter.rated,
            home.collectionRatingText.value,
          ),
          _QuickStat.count(
            'Rare',
            Icons.diamond_rounded,
            CollectionFilter.rare,
            home.totalRareCount.value,
          ),
          _QuickStat.count(
            'Duplicates',
            Icons.copy_all_rounded,
            CollectionFilter.duplicates,
            counts.duplicates,
          ),
          _QuickStat.count(
            'Doubled',
            Icons.rocket_launch_rounded,
            CollectionFilter.doubled,
            counts.doubled,
          ),
          _QuickStat.count(
            'Gaining',
            Icons.trending_up_rounded,
            CollectionFilter.gaining,
            counts.gaining,
          ),
          _QuickStat.count(
            'Losing',
            Icons.trending_down_rounded,
            CollectionFilter.losing,
            counts.losing,
          ),
        ];

        final width = (constraints.maxWidth - _gap) / 2;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final (i, stat) in stats.indexed)
              StaggeredEntrance(
                index: i,
                offsetY: 0.15,
                child: SizedBox(
                  width: width,
                  height: _tileHeight,
                  child: AppPressable(
                    onTap: () => onOpen(stat.filter),
                    haptic: PressHaptic.selection,
                    semanticLabel: 'Show ${stat.filter.label.toLowerCase()}',
                    child: _StatTile(stat: stat),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final _QuickStat stat;

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppTextStyles.numberM().copyWith(fontSize: 18);

    return AppCard(
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(stat.icon, size: 18, color: AppColors.goldAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              stat.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label().copyWith(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: 6),
          // Right-aligned in a fixed slot: "1,234" fits at full size, and
          // anything wider shrinks rather than pushing the label out.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 64),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: stat.isRating
                  ? Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: stat.ratingText, style: valueStyle),
                          if (stat.ratingText != '—')
                            TextSpan(
                              text: '/10',
                              style: AppTextStyles.caption().copyWith(
                                color: AppColors.textStatLabel,
                              ),
                            ),
                        ],
                      ),
                    )
                  : AnimatedCountText(
                      value: (stat.count ?? 0).toDouble(),
                      style: valueStyle,
                      format: (v) => _count.format(v.round()),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
