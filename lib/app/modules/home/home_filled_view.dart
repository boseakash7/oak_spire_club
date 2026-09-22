import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/price_formatter.dart';
import '../../core/widgets/animated_count_text.dart';
import '../../core/widgets/animated_list_entrance.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_header.dart';
import '../../data/models/collection_item_display.dart';
import 'home_controller.dart';
import 'widgets/home_chart_footer.dart';
import 'widgets/home_value_chart.dart';

/// One Quick Stats tile. Modelled as data so the row is a list, not a switch
/// over hard-coded indices.
class _QuickStat {
  const _QuickStat.count(this.label, int this.count)
    : ratingText = null,
      isRating = false;

  const _QuickStat.rating(this.label, String this.ratingText)
    : count = null,
      isRating = true;

  final String label;
  final int? count;
  final String? ratingText;
  final bool isRating;
}

List<_QuickStat> _quickStats(HomeController home) => [
  _QuickStat.count('Total\nCollection', home.totalCollectionCount.value),
  _QuickStat.count('Total\nDrunk', home.totalDrunkCount.value),
  _QuickStat.rating('Collection\nRating', home.collectionRatingText.value),
  _QuickStat.count('Rare\nBottles', home.totalRareCount.value),
];

/// Space between Top moved heading and its horizontal cards.
/// Keep consistent with Quick Stats spacing.
const double _kHomeHeadingToCardsGap = 12;

/// Space between Top moved bottles row and Quick Stats section.
/// Keep consistent with Quick Stats spacing.
const double _kTopMovedToQuickStatsGap = 12;

/// Space between Quick Stats heading and stat cards (tighter than Top moved).
const double _kQuickStatsHeadingToCardsGap = 12;

class HomeFilledView extends StatelessWidget {
  const HomeFilledView({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surfaceDeep, AppColors.surfaceDeep],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
          SafeArea(
            top: false,
            child: RefreshIndicator(
              color: AppColors.gold1,
              onRefresh: home.forceReload,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  23,
                  kShellTabBodyContentTopGap,
                  0,
                  96,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 23),
                      child: _CollectionValue(home: home),
                    ),
                    const SizedBox(height: 38),
                    Padding(
                      padding: const EdgeInsets.only(right: 23),
                      child: const _SectionHeader(title: 'Top moved bottles'),
                    ),
                    const SizedBox(height: _kHomeHeadingToCardsGap),
                    Obx(() {
                      final bottles = home.topMovedBottles;
                      if (bottles.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(right: 23),
                          child: _NoMovementYet(),
                        );
                      }
                      return SizedBox(
                        height: 68,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.only(left: 0, right: 23),
                          itemCount: bottles.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final item = bottles[index];
                            final subtitle = item.lineSubtitle.trim().isNotEmpty
                                ? item.lineSubtitle.trim()
                                : item.proofLabel;
                            final movementRaw = item.priceMovementRaw;
                            return AnimatedListEntrance(
                              index: index,
                              child: _TrendingCard(
                                title: item.lineTitle,
                                subtitle: subtitle,
                                price: item.marketAverageLabel,
                                changeText:
                                    PriceFormatter.formatPriceMovementLabel(
                                      movementRaw,
                                    ),
                                changeColor: PriceFormatter.priceMovementColor(
                                  movementRaw,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: _kTopMovedToQuickStatsGap),
                    Padding(
                      padding: const EdgeInsets.only(right: 23),
                      child: const _SectionHeader(title: 'Quick Stats'),
                    ),
                    const SizedBox(height: _kQuickStatsHeadingToCardsGap),
                    SizedBox(
                      height: 100,
                      child: Obx(() {
                        final stats = _quickStats(home);
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.only(left: 0, right: 8),
                          itemCount: stats.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final stat = stats[index];
                            return AnimatedListEntrance(
                              index: index,
                              child: stat.isRating
                                  ? _StatCardRating(
                                      label: stat.label,
                                      value: stat.ratingText ?? '—',
                                    )
                                  : _StatCard(
                                      label: stat.label,
                                      count: stat.count ?? 0,
                                    ),
                            );
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    // Full-bleed chart (~2px from screen edges), like benchmark detail.
                    LayoutBuilder(
                      builder: (context, _) {
                        const parentLeftPad = 23.0;
                        final bleed = parentLeftPad - kHomeChartHorizontalInset;
                        final w =
                            MediaQuery.sizeOf(context).width -
                            kHomeChartHorizontalInset * 2;
                        return Transform.translate(
                          offset: Offset(-bleed, 0),
                          child: SizedBox(
                            width: w,
                            child: const HomeValueChart(),
                          ),
                        );
                      },
                    ),
                    // Legend + range chips: align with Collection Value (23px).
                    const Padding(
                      padding: EdgeInsets.only(right: 23),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 14),
                          HomeChartLegend(),
                          HomeChartFooter(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionValue extends StatelessWidget {
  const _CollectionValue({required this.home});

  final HomeController home;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The heading has to match the number below it: when no bottle in the
        // collection carries a bluebook price there is no market value to
        // show, and calling cost basis "value" would be wrong.
        Obx(
          () => Text(
            home.showingInvestedAsValue.value
                ? 'Total Invested'
                : 'Collection Value',
            style: AppTextStyles.titleL(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => AppTextStyles
                        .collectionValueGradient
                        .createShader(bounds),
                    child: Obx(
                      () => AnimatedCountText(
                        value: home.collectionValue.value,
                        format: _formatWholeDollars,
                        style: AppTextStyles.displayXl(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Cost basis, shown only when it is the supporting figure
                  // rather than the headline.
                  Obx(() {
                    if (home.showingInvestedAsValue.value) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Invested ${home.investedValueText.value}',
                        style: AppTextStyles.caption(),
                      ),
                    );
                  }),
                  Obx(() => _HomeMovedLine(text: home.movedText.value)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Obx(
              () => _GainChip(
                gain: home.unrealisedGain.value,
                label: home.unrealisedGainText.value,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Whole-dollar formatting for the counting hero value. Kept local so the
/// count-up animation does not rebuild a NumberFormat every frame.
final _wholeDollars = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 0,
);

String _formatWholeDollars(double v) =>
    v <= 0 ? r'$ —' : _wholeDollars.format(v);

/// Unrealised gain / loss beside the hero value: the one figure on this screen
/// that is not shown anywhere else. Hidden when market value is unknown.
class _GainChip extends StatelessWidget {
  const _GainChip({required this.gain, required this.label});

  final double? gain;
  final String label;

  @override
  Widget build(BuildContext context) {
    final value = gain;
    if (value == null || label.isEmpty) return const SizedBox.shrink();

    final up = value >= 0;
    final tint = up ? AppColors.trendPositive : AppColors.trendNegative;

    return AppCard(
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Unrealised', style: AppTextStyles.micro()),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 16,
                color: tint,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.bodyM().copyWith(
                  color: tint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown when the collection has no price movement to rank yet.
class _NoMovementYet extends StatelessWidget {
  const _NoMovementYet();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      compact: true,
      icon: Icons.show_chart_rounded,
      title: 'No movement yet',
      message:
          'Once your bottles have tracked price history, the biggest movers '
          'show up here.',
    );
  }
}

/// “Moved +64% in last 3 months” — percent matches collection value gold.
class _HomeMovedLine extends StatelessWidget {
  const _HomeMovedLine({required this.text});

  final String text;

  static final _withPercent = RegExp(r'^Moved (.+?) in (.+)$');

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.homeMovedSubtitle();
    final match = _withPercent.firstMatch(text);
    if (match == null) {
      return Text(text, style: base);
    }

    final percentPart = match.group(1)!;
    final periodPart = match.group(2)!;
    final showGoldPercent =
        percentPart != '—' && RegExp(r'%').hasMatch(percentPart);

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'Moved '),
          if (showGoldPercent)
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) =>
                    AppTextStyles.collectionValueGradient.createShader(bounds),
                child: Text(
                  percentPart,
                  style: base.copyWith(color: AppColors.white),
                ),
              ),
            )
          else
            TextSpan(text: percentPart),
          TextSpan(text: ' in $periodPart'),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.bodyL());
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.changeText,
    required this.changeColor,
  });

  final String title;
  final String subtitle;
  final String price;
  final String changeText;
  final Color changeColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      width: 262,
      height: 68,
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyL(),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyS().copyWith(
                    color: AppColors.textTrendingSubtitle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                changeText,
                style: AppTextStyles.bodyM().copyWith(color: changeColor),
              ),
              const Spacer(),
              Text(
                price,
                style: AppTextStyles.bodyM().copyWith(
                  color: AppColors.textCream,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shared geometry + label treatment for the Quick Stats tiles.
const double _kStatCardSide = 100;
const EdgeInsets _kStatCardPadding = EdgeInsets.fromLTRB(13, 12, 13, 14);

TextStyle _statLabelStyle() => AppTextStyles.label().copyWith(
  color: AppColors.textStatLabel,
  height: 1.05,
);

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      width: _kStatCardSide,
      height: _kStatCardSide,
      padding: _kStatCardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _statLabelStyle()),
          const Spacer(),
          AnimatedCountInt(value: count, style: AppTextStyles.numberL()),
        ],
      ),
    );
  }
}

class _StatCardRating extends StatelessWidget {
  const _StatCardRating({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      width: _kStatCardSide,
      height: _kStatCardSide,
      padding: _kStatCardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _statLabelStyle()),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(value, style: AppTextStyles.numberL()),
                const SizedBox(width: 6),
                const Icon(
                  Icons.star_rounded,
                  size: 22,
                  color: AppColors.textCream,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
