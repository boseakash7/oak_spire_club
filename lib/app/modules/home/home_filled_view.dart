import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/animations/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/price_formatter.dart';
import '../../core/widgets/app_header.dart';
import '../../data/collection_value_calculator.dart';
import '../../data/models/collection_item_display.dart';
import 'home_controller.dart';
import 'widgets/home_chart_footer.dart';
import 'widgets/home_value_chart.dart';

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
          colors: [Color(0xFF080405), Color(0xFF080405)],
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
                      return const SizedBox.shrink();
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
                          return _TrendingCard(
                            title: item.lineTitle,
                            subtitle: subtitle,
                            price: item.marketAverageLabel,
                            changeText: PriceFormatter.formatPriceMovementLabel(
                              movementRaw,
                            ),
                            changeColor: PriceFormatter.priceMovementColor(
                              movementRaw,
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
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      padding: const EdgeInsets.only(left: 0, right: 8),
                      itemCount: 4,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        if (index == 2) {
                          return Obx(
                            () => _StatCardRating(
                              label: 'Collection\nRating',
                              value: home.collectionRatingText.value,
                            ),
                          );
                        }
                        final label = switch (index) {
                          0 => 'Total\nCollection',
                          1 => 'Total\nDrunk',
                          3 => 'Rare\nBottles',
                          _ => 'Total\nCollection',
                        };
                        return Obx(
                          () => _StatCard(
                            label: label,
                            value: switch (index) {
                              0 => home.totalCollectionCount.value,
                              1 => home.totalDrunkCount.value,
                              3 => home.totalRareCount.value,
                              _ => home.totalCollectionCount.value,
                            }.toString(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Full-bleed chart (~2px from screen edges), like benchmark detail.
                  LayoutBuilder(
                    builder: (context, _) {
                      const parentLeftPad = 23.0;
                      final bleed = parentLeftPad - kHomeChartHorizontalInset;
                      final w = MediaQuery.sizeOf(context).width -
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
        Text(
          'Collection Value',
          style: AppTextStyles.body16().copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFF1E8BE),
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
                      () => Text(
                        home.collectionValueText.value,
                        style: AppTextStyles.button20Bold().copyWith(
                          fontSize: 36,
                          height: 1.12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => _HomeMovedLine(text: home.movedText.value)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Obx(() {
              final percent = home.collectionMovedPercent.value;
              return _CollectionValueMiniBars(
                movedFraction:
                    CollectionValueCalculator.movedBarFractionFromPercent(
                  percent,
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

/// Mini bars beside collection value: left = moved %, right = 100% reference.
class _CollectionValueMiniBars extends StatefulWidget {
  const _CollectionValueMiniBars({required this.movedFraction});

  /// Same % as “Moved +64% …” (0–1).
  final double movedFraction;

  @override
  State<_CollectionValueMiniBars> createState() =>
      _CollectionValueMiniBarsState();
}

class _CollectionValueMiniBarsState extends State<_CollectionValueMiniBars>
    with SingleTickerProviderStateMixin {
  static const double _maxHeight = 52;
  static const double _barWidth = 16;
  static const double _gap = 8;
  static const double _barRadius = 1;

  static const Color _barColor = AppColors.gold2;

  late final AnimationController _fillController;
  double _leftBegin = 0;
  double _leftEnd = 0;
  double _rightBegin = 0;
  double _rightEnd = 1;

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      vsync: this,
      duration: AppMotion.chartDraw,
    )..addListener(() => setState(() {}));
    _leftEnd = widget.movedFraction;
    _rightEnd = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fillController.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(covariant _CollectionValueMiniBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movedFraction == widget.movedFraction) return;
    final t = AppMotion.chart.transform(_fillController.value);
    _leftBegin = _lerp(_leftBegin, _leftEnd, t);
    _rightBegin = _lerp(_rightBegin, _rightEnd, t);
    _leftEnd = widget.movedFraction;
    _rightEnd = 1;
    _fillController.forward(from: 0);
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _animatedLeftHeight(double t) =>
      _maxHeight * _lerp(_leftBegin, _leftEnd, t);

  double _animatedRightHeight(double t) =>
      _maxHeight * _lerp(_rightBegin, _rightEnd, t);

  @override
  Widget build(BuildContext context) {
    final t = AppMotion.chart.transform(_fillController.value);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _MiniBar(height: _animatedLeftHeight(t)),
        const SizedBox(width: _gap),
        _MiniBar(height: _animatedRightHeight(t)),
      ],
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _CollectionValueMiniBarsState._barWidth,
      height: height,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(_CollectionValueMiniBarsState._barRadius),
        color: _CollectionValueMiniBarsState._barColor,
      ),
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
    return Text(
      title,
      style: AppTextStyles.body16().copyWith(color: AppColors.white),
    );
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
    return Container(
      width: 262,
      height: 68,
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A342E)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF271C16), Color(0xFF201512)],
        ),
      ),
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
                  style: AppTextStyles.body16().copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 14,
                    color: const Color(0xFF87665A),
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
                style: AppTextStyles.body16().copyWith(
                  fontSize: 15,
                  color: changeColor,
                ),
              ),
              const Spacer(),
              Text(
                price,
                style: AppTextStyles.body16().copyWith(
                  fontSize: 15,
                  color: const Color(0xFFF1E8BE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A342E)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF271C16), Color(0xFF201512)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.body16().copyWith(
              fontSize: 13,
              color: const Color(0xFF997C71),
              height: 1.05,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.body16().copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF1E8BE),
            ),
          ),
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
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A342E)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF271C16), Color(0xFF201512)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.body16().copyWith(
              fontSize: 13,
              color: const Color(0xFF997C71),
              height: 1.05,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF1E8BE),
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.star_rounded,
                  size: 22,
                  color: const Color(0xFFF1E8BE),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
