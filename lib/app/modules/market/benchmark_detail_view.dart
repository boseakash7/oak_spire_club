import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../core/animations/app_motion.dart';
import '../../core/analytics/app_analytics_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/network/app_cache_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/utils/price_formatter.dart';
import 'benchmark_detail_controller.dart';

FlLine _benchmarkDottedGridLine(double _) => FlLine(
  color: AppColors.chartGridLine,
  strokeWidth: 0.7,
  dashArray: const [3, 4],
);

Widget _chartRangeChip(
  BenchmarkDetailController controller,
  BenchmarkDetailChartRange range,
) {
  final selected = controller.selectedChartRange.value == range;
  return InkWell(
    borderRadius: BorderRadius.circular(6),
    onTap: () => unawaited(controller.setChartRange(range)),
    child: Container(
      width: 33,
      height: 33,
      decoration: BoxDecoration(
        color: selected ? AppColors.gold2 : AppColors.surfaceChip,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected
              ? AppColors.tagGoldBorder
              : AppColors.tagInactiveBorder,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        range.label,
        style: AppTextStyles.body16().copyWith(
          fontSize: 13,
          color: AppColors.white,
        ),
      ),
    ),
  );
}

List<Widget> _collectionTrendWidgets({
  required String? movementRaw,
  required String movementLabel,
  required Color movementColor,
  required double? gainDollars,
}) {
  final widgets = <Widget>[];

  if (gainDollars != null) {
    final gainColor = gainDollars >= 0
        ? AppColors.trendPositive
        : AppColors.marketTrendDown;
    widgets.add(
      Text(
        PriceFormatter.format(gainDollars.abs().round().toString()),
        style: AppTextStyles.body16().copyWith(
          fontSize: 12,
          color: gainColor,
        ),
      ),
    );
  }

  if (movementLabel == '—') {
    if (widgets.isEmpty) {
      widgets.add(
        Text(
          '—',
          style: AppTextStyles.body16().copyWith(
            fontSize: 12,
            color: AppColors.textWolf,
          ),
        ),
      );
    }
    return widgets;
  }

  if (widgets.isNotEmpty) {
    widgets.add(const SizedBox(width: 4));
    widgets.add(
      Text(
        '($movementLabel)',
        style: AppTextStyles.body16().copyWith(
          fontSize: 12,
          color: movementColor,
        ),
      ),
    );
    return widgets;
  }

  final kind = PriceFormatter.priceMovementArrowKind(movementRaw);
  if (kind == 'up') {
    widgets.add(
      SvgPicture.asset(
        AppAssets.iconArrowUp,
        width: 10,
        height: 10,
        colorFilter: ColorFilter.mode(movementColor, BlendMode.srcIn),
      ),
    );
  } else if (kind == 'down') {
    widgets.add(
      SvgPicture.asset(
        AppAssets.iconArrowDown,
        width: 10,
        height: 10,
        colorFilter: ColorFilter.mode(movementColor, BlendMode.srcIn),
      ),
    );
  } else {
    widgets.add(Icon(Icons.horizontal_rule, size: 12, color: movementColor));
  }
  widgets.add(const SizedBox(width: 4));
  widgets.add(
    Text(
      movementLabel,
      style: AppTextStyles.body16().copyWith(
        fontSize: 12,
        color: movementColor,
      ),
    ),
  );
  return widgets;
}

class BenchmarkDetailView extends GetView<BenchmarkDetailController> {
  const BenchmarkDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDeep,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.surfaceDeep, AppColors.surfaceDeep],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: AppColors.overlayBlack20),
            ),
            SafeArea(
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 10, 23, 0),
                      child: Row(
                        children: [
                          AppBackButton(
                            color: AppColors.white,
                            constraints: const BoxConstraints.tightFor(
                              width: 30,
                              height: 30,
                            ),
                            onPressed: () {
                              if (Get.isRegistered<AppAnalyticsController>()) {
                                unawaited(
                                  AppAnalyticsController.to.logTap(
                                    'benchmark_detail_back',
                                  ),
                                );
                              }
                              Get.back<void>();
                            },
                          ),
                          const Spacer(),
                          Text(
                            controller.greetingText,
                            style: AppTextStyles.body16().copyWith(
                              fontSize: 14,
                              color: AppColors.textGreeting,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(23, 22, 23, 20),
                      child: _TopSummary(
                        name: controller.productName,
                        avg: controller.avgFormatted,
                        low: controller.lowFormatted,
                        high: controller.highFormatted,
                        imageUrl: controller.imageUrl,
                        placeholder: _placeholder(),
                        ratingChipLabel: controller.ratingDisplay ?? '—',
                        priceMovementRaw: controller.priceMovementRaw,
                        proofLine: controller.proofText,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        const _BenchmarkPriceChart(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(23, 14, 23, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: 14,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.chartLineMarketValue,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Market Value',
                                style: AppTextStyles.body16().copyWith(
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 22),
                              Container(
                                width: 14,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.chartLineBsmi,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'BSMI',
                                style: AppTextStyles.body16().copyWith(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(23, 16, 23, 0),
                          child: Row(
                            children: [
                              Obx(() {
                                return Row(
                                  children: [
                                    for (
                                      var i = 0;
                                      i <
                                          BenchmarkDetailChartRange
                                              .values
                                              .length;
                                      i++
                                    ) ...[
                                      if (i > 0) const SizedBox(width: 10),
                                      _chartRangeChip(
                                        controller,
                                        BenchmarkDetailChartRange.values[i],
                                      ),
                                    ],
                                  ],
                                );
                              }),
                              const Spacer(),
                              GestureDetector(
                                onTap: () async {
                                  if (Get.isRegistered<
                                    AppAnalyticsController
                                  >()) {
                                    unawaited(
                                      AppAnalyticsController.to.logTap(
                                        'benchmark_detail_add_to_collection',
                                      ),
                                    );
                                  }
                                  await controller.openAddToCollection();
                                },
                                child: Container(
                                  height: 33,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: AppColors.goldGradient,
                                  ),
                                  child: Obx(
                                    () {
                                      final inCollection =
                                          controller.hasInCollection.value;
                                      final label = inCollection
                                          ? 'Edit collection'
                                          : '+ Add to collection';
                                      final textStyle =
                                          AppTextStyles.body16().copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.black,
                                      );
                                      if (!inCollection) {
                                        return Text(label, style: textStyle);
                                      }
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 14,
                                            color: AppColors.black,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(label, style: textStyle),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(23, 16, 23, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Details',
                                    style: AppTextStyles.body16().copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (controller.descriptionText != null &&
                                      controller
                                          .descriptionText!
                                          .isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 19,
                                      height: 19,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceChip,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'AI',
                                          style: AppTextStyles.body16()
                                              .copyWith(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                controller.descriptionText?.trim().isNotEmpty ==
                                        true
                                    ? controller.descriptionText!.trim()
                                    : 'No description available.',
                                style: AppTextStyles.body16().copyWith(
                                  fontSize: 14,
                                  height: 1.1,
                                  color:
                                      controller.descriptionText
                                              ?.trim()
                                              .isNotEmpty ==
                                          true
                                      ? AppColors.white
                                      : AppColors.textWolf,
                                ),
                              ),
                              Obx(() {
                                if (!controller.hasInCollection.value) {
                                  return const SizedBox.shrink();
                                }
                                const fillBarWidth = 110.0;
                                final fillW =
                                    (fillBarWidth * controller.collectionFillRatio.value)
                                        .clamp(4.0, fillBarWidth);
                                final movementRaw =
                                    controller.collectionPriceMovementRaw.value;
                                final movementColor =
                                    PriceFormatter.priceMovementColor(
                                  movementRaw,
                                );
                                final movementLabel =
                                    PriceFormatter.formatPriceMovementLabel(
                                  movementRaw,
                                );
                                final gain =
                                    controller.collectionGainDollars.value;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    Text(
                                      'You have this',
                                      style: AppTextStyles.body16().copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          'Bought at',
                                          style: AppTextStyles.body16()
                                              .copyWith(
                                                fontSize: 12,
                                                color:
                                                    AppColors.textOwnedLabel,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${controller.collectionPaidLabel.value} (${controller.collectionQuantity.value})',
                                          style: AppTextStyles.body16()
                                              .copyWith(
                                                fontSize: 12,
                                                color: AppColors.textCream,
                                              ),
                                        ),
                                        const SizedBox(width: 10),
                                        ..._collectionTrendWidgets(
                                          movementRaw: movementRaw,
                                          movementLabel: movementLabel,
                                          movementColor: movementColor,
                                          gainDollars: gain,
                                        ),
                                        const Spacer(),
                                        Container(
                                          width: fillBarWidth,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: AppColors.fillBarTrack,
                                            borderRadius:
                                                BorderRadius.circular(27),
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              width: fillW,
                                              height: 9,
                                              decoration: BoxDecoration(
                                                color: AppColors.goldRich,
                                                borderRadius:
                                                    BorderRadius.circular(27),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Image.asset(
      AppAssets.collectionBottlePlaceholder,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
  }
}

class _BenchmarkPriceChart extends GetView<BenchmarkDetailController> {
  const _BenchmarkPriceChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 188,
      child: Obx(() {
        if (controller.chartLoading.value) {
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold1,
              ),
            ),
          );
        }
        if (controller.chartError.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                controller.chartError.value!,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body16().copyWith(
                  fontSize: 12,
                  color: AppColors.textWolf,
                ),
              ),
            ),
          );
        }
        final pts = controller.chartPoints.toList(growable: false);
        if (pts.isEmpty) {
          return Center(
            child: Text(
              'No chart data for this range',
              style: AppTextStyles.body16().copyWith(
                fontSize: 12,
                color: AppColors.textWolf,
              ),
            ),
          );
        }

        final spots = <FlSpot>[];
        for (var i = 0; i < pts.length; i++) {
          spots.add(FlSpot(i.toDouble(), pts[i].price));
        }
        if (spots.length == 1) {
          spots.add(FlSpot(1, spots.first.y));
        }

        final bsmiVals = controller.chartBsmiValues.toList(growable: false);
        final bsmiSpots = <FlSpot>[];
        if (bsmiVals.length == pts.length) {
          for (var i = 0; i < pts.length; i++) {
            bsmiSpots.add(FlSpot(i.toDouble(), bsmiVals[i]));
          }
          if (bsmiSpots.length == 1) {
            bsmiSpots.add(FlSpot(1, bsmiSpots.first.y));
          }
        }

        final ys = <double>[...pts.map((e) => e.price)];
        if (bsmiSpots.isNotEmpty) {
          ys.addAll(bsmiVals);
        }
        var minY = ys.reduce(math.min);
        var maxY = ys.reduce(math.max);
        if (minY == maxY) {
          minY -= 1;
          maxY += 1;
        } else {
          final pad = (maxY - minY) * 0.12;
          minY -= pad;
          maxY += pad;
        }

        final maxX = math.max(
          spots.isEmpty ? 1.0 : spots.last.x,
          bsmiSpots.isEmpty ? 0.0 : bsmiSpots.last.x,
        );
        final maxXSafe = math.max(maxX, 1.0);
        final hInterval = (maxY - minY) / 4;
        final vInterval = maxXSafe / 4;

        return LineChart(
          LineChartData(
            minX: 0,
            maxX: maxXSafe,
            minY: minY,
            maxY: maxY,
            lineTouchData: const LineTouchData(enabled: false),
            titlesData: const FlTitlesData(show: false),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: minY,
                  color: AppColors.chartGridLine,
                  strokeWidth: 1,
                  dashArray: const [3, 4],
                ),
                HorizontalLine(
                  y: maxY,
                  color: AppColors.chartGridLine,
                  strokeWidth: 1,
                  dashArray: const [3, 4],
                ),
              ],
            ),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: true,
              horizontalInterval: hInterval > 0 ? hInterval : 1,
              verticalInterval: vInterval > 0 ? vInterval : 1,
              getDrawingHorizontalLine: _benchmarkDottedGridLine,
              getDrawingVerticalLine: _benchmarkDottedGridLine,
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: pts.length > 2,
                color: AppColors.chartLineMarketValue,
                barWidth: 2,
                dotData: FlDotData(
                  show: pts.length <= 6,
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: AppColors.chartLineMarketValue,
                    );
                  },
                ),
              ),
              if (bsmiSpots.isNotEmpty)
                LineChartBarData(
                  spots: bsmiSpots,
                  isCurved: pts.length > 2,
                  color: AppColors.chartLineBsmi,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: pts.length <= 6,
                    getDotPainter: (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.chartLineBsmi,
                      );
                    },
                  ),
                ),
            ],
            backgroundColor: AppColors.chartPlotBackground,
          ),
          duration: AppMotion.chartDraw,
          curve: AppMotion.chart,
        );
      }),
    );
  }
}

class _TopSummary extends StatelessWidget {
  const _TopSummary({
    required this.name,
    required this.avg,
    required this.low,
    required this.high,
    required this.imageUrl,
    required this.placeholder,
    required this.ratingChipLabel,
    this.priceMovementRaw,
    this.proofLine,
  });

  final String name;
  final String avg;
  final String low;
  final String high;
  final String? imageUrl;
  final Widget placeholder;
  final String ratingChipLabel;
  final String? priceMovementRaw;
  final String? proofLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + bottle image (top-aligned; image sits right like Figma).
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body16().copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.2,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Price row: main price + trend on one line, vertically centered (Figma).
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        avg,
                        style: AppTextStyles.body16().copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textCream,
                          height: 1.0,
                        ),
                      ),
                      ..._priceMovementWidgets(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$low - $high',
                    style: AppTextStyles.body16().copyWith(
                      fontSize: 10,
                      height: 1.2,
                      color: AppColors.textWolf,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 118,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: AppColors.cardSurfaceGradient,
              ),
              child: Center(
                child: SizedBox(
                  width: 77,
                  height: 77,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.bottleRadialGlow,
                        ),
                      ),
                      if (imageUrl != null)
                        CachedNetworkImage(
                          imageUrl: imageUrl!,
                          cacheManager: AppCacheManager.images,
                          fit: BoxFit.contain,
                          placeholder: (context, _) => placeholder,
                          errorWidget: (context, error, stackTrace) =>
                              placeholder,
                        )
                      else
                        placeholder,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        _ratingChipInline(ratingChipLabel),
        if (proofLine != null && proofLine!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            proofLine!.trim(),
            style: AppTextStyles.body16().copyWith(
              fontSize: 11,
              height: 1.2,
              color: AppColors.textWolf,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _priceMovementWidgets() {
    final label = PriceFormatter.formatPriceMovementLabel(priceMovementRaw);
    if (label == '—') {
      return [
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.body16().copyWith(
            fontSize: 12,
            height: 1.0,
            color: AppColors.textWolf,
          ),
        ),
      ];
    }
    final color = PriceFormatter.priceMovementColor(priceMovementRaw);
    final kind = PriceFormatter.priceMovementArrowKind(priceMovementRaw);
    return [
      const SizedBox(width: 10),
      if (kind == 'up')
        SvgPicture.asset(
          AppAssets.iconArrowUp,
          width: 10,
          height: 10,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        )
      else if (kind == 'down')
        SvgPicture.asset(
          AppAssets.iconArrowDown,
          width: 10,
          height: 10,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        )
      else
        Icon(Icons.horizontal_rule, size: 12, color: color),
      const SizedBox(width: 4),
      Text(
        label,
        style: AppTextStyles.body16().copyWith(
          fontSize: 12,
          height: 1.0,
          color: color,
        ),
      ),
    ];
  }

  Widget _ratingChipInline(String ratingLabel) {
    return Container(
      height: 23,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.ratingChipBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppAssets.star,
            width: 8,
            height: 8,
            colorFilter: const ColorFilter.mode(
              AppColors.ratingStarMuted,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            ratingLabel,
            style: AppTextStyles.body16().copyWith(
              fontSize: 13,
              color: AppColors.ratingStarMuted,
            ),
          ),
        ],
      ),
    );
  }
}
