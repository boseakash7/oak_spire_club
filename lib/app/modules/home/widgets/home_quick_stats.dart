import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/animations/staggered_entrance.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_count_text.dart';
import '../../../core/widgets/app_card.dart';
import '../home_controller.dart';

/// One Quick Stats tile. Modelled as data so the row is a list, not a switch
/// over hard-coded indices.
class _QuickStat {
  const _QuickStat.count(this.label, this.icon, int this.count)
    : ratingText = null;

  const _QuickStat.rating(this.label, this.icon, String this.ratingText)
    : count = null;

  final String label;
  final IconData icon;
  final int? count;
  final String? ratingText;

  bool get isRating => ratingText != null;
}

/// "Quick Stats": collection size, bottles opened, rating, rare finds.
class HomeQuickStats extends StatelessWidget {
  const HomeQuickStats({super.key, required this.home});

  final HomeController home;

  static const double _side = 100;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _side,
      child: Obx(() {
        final stats = [
          _QuickStat.count(
            'Total\nCollection',
            Icons.liquor_rounded,
            home.totalCollectionCount.value,
          ),
          _QuickStat.count(
            'Total\nDrunk',
            Icons.local_bar_rounded,
            home.totalDrunkCount.value,
          ),
          _QuickStat.rating(
            'Collection\nRating',
            Icons.star_rounded,
            home.collectionRatingText.value,
          ),
          _QuickStat.count(
            'Rare\nBottles',
            Icons.diamond_rounded,
            home.totalRareCount.value,
          ),
        ];

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.only(right: 8),
          itemCount: stats.length,
          separatorBuilder: (context, index) => const SizedBox(width: 14),
          itemBuilder: (context, index) => StaggeredEntrance(
            index: index,
            offsetY: 0.15,
            child: _StatTile(stat: stats[index]),
          ),
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
    final valueStyle = AppTextStyles.numberL();

    return AppCard(
      width: HomeQuickStats._side,
      height: HomeQuickStats._side,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
      child: Stack(
        children: [
          // Faint glyph in the corner gives each tile an identity at a glance.
          Positioned(
            right: -6,
            bottom: -8,
            child: Icon(
              stat.icon,
              size: 44,
              color: AppColors.goldAccent.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.label,
                style: AppTextStyles.label().copyWith(
                  color: AppColors.textStatLabel,
                  height: 1.05,
                ),
              ),
              const Spacer(),
              if (stat.isRating)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(stat.ratingText!, style: valueStyle),
                      if (stat.ratingText != '—')
                        Text(
                          '/10',
                          style: AppTextStyles.caption().copyWith(
                            color: AppColors.textStatLabel,
                          ),
                        ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.star_rounded,
                        size: 22,
                        color: AppColors.textCream,
                      ),
                    ],
                  ),
                )
              else
                AnimatedCountInt(value: stat.count ?? 0, style: valueStyle),
            ],
          ),
        ],
      ),
    );
  }
}
