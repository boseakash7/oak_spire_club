import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../core/animations/staggered_entrance.dart';
import '../../core/platform/app_platform.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_add_pill.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_segmented_range.dart';
import '../../core/widgets/bottle_image.dart';
import 'benchmark_detail_controller.dart';
import 'widgets/benchmark_deal_check.dart';
import 'widgets/benchmark_facts.dart';
import 'widgets/benchmark_ownership_card.dart';
import 'widgets/benchmark_price_chart.dart';
import 'widgets/benchmark_top_summary.dart';

const double _kInset = 23;

/// One bottle: a large hero of the bottle that collapses into the app bar,
/// its price summary, the price chart, and what the user owns of it.
class BenchmarkDetailView extends GetView<BenchmarkDetailController> {
  const BenchmarkDetailView({super.key});

  static const double _expandedHeight = 300;

  void _logTap(String key) {
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(AppAnalyticsController.to.logTap(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDeep,
      body: RefreshIndicator.adaptive(
        onRefresh: controller.reload,
        edgeOffset: kToolbarHeight + MediaQuery.paddingOf(context).top,
        child: CustomScrollView(
          physics: AppPlatform.scrollPhysics,
          slivers: [
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: _expandedHeight,
              backgroundColor: AppColors.surfaceDeep,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Center(
                  child: _GlassCircle(
                    child: AppBackButton(
                      color: AppColors.white,
                      onPressed: () {
                        _logTap('benchmark_detail_back');
                        Get.back<void>();
                      },
                    ),
                  ),
                ),
              ),
              flexibleSpace: _HeroHeader(
                expandedHeight: _expandedHeight,
                title: controller.productName,
                image: BottleImage(
                  url: controller.imageUrl,
                  bottleId: controller.bottleId,
                  glow: false,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(_kInset, 8, _kInset, 0),
              sliver: SliverToBoxAdapter(
                child: const FadeSlideEntrance(child: BenchmarkTopSummary()),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            const SliverToBoxAdapter(
              child: FadeSlideEntrance(index: 2, child: BenchmarkPriceChart()),
            ),
            SliverPadding(
              // Clear Android's navigation bar (the app draws edge to edge).
              padding: EdgeInsets.fromLTRB(
                _kInset,
                14,
                _kInset,
                32 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverToBoxAdapter(
                child: FadeSlideEntrance(
                  index: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BenchmarkChartLegend(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Obx(
                            () => AppSegmentedRange<BenchmarkDetailChartRange>(
                              values: BenchmarkDetailChartRange.values,
                              selected: controller.selectedChartRange.value,
                              labelOf: (r) => r.label,
                              onChanged: (r) =>
                                  unawaited(controller.setChartRange(r)),
                            ),
                          ),
                          const Spacer(),
                          Obx(() {
                            final owned = controller.hasInCollection.value;
                            return AppAddPill(
                              label: owned ? 'Edit collection' : 'Add',
                              icon: owned
                                  ? Icons.edit_outlined
                                  : Icons.add_rounded,
                              onTap: () async {
                                _logTap('benchmark_detail_add_to_collection');
                                await controller.openAddToCollection();
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const BenchmarkDealCheck(),
                      const BenchmarkFacts(),
                      const BenchmarkOwnershipCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bottle over a warm glow. As the page scrolls it parallaxes and fades
/// out while the bottle's name fades into the pinned bar.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.expandedHeight,
    required this.title,
    required this.image,
  });

  final double expandedHeight;
  final String title;
  final Widget image;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final minHeight = kToolbarHeight + topPad;

    return LayoutBuilder(
      builder: (context, constraints) {
        final range = expandedHeight + topPad - minHeight;
        // 1 fully expanded, 0 collapsed; >1 while over-stretched.
        final t = range <= 0
            ? 0.0
            : ((constraints.maxHeight - minHeight) / range).clamp(0.0, 1.4);
        final visible = t.clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 0.1),
                  radius: 0.75,
                  colors: [AppColors.bottleGlowGold, AppColors.surfaceDeep],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: topPad + 12 - (1 - visible) * 40,
              bottom: 12,
              child: Opacity(
                opacity: Curves.easeOut.transform(visible),
                child: Transform.scale(
                  scale: 0.85 + 0.15 * t,
                  child: Center(
                    child: SizedBox(
                      height: expandedHeight - 40,
                      width: expandedHeight - 40,
                      child: image,
                    ),
                  ),
                ),
              ),
            ),
            // Bottom fade into the page.
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00080405), AppColors.surfaceDeep],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 64,
              right: 24,
              top: topPad,
              height: kToolbarHeight,
              child: IgnorePointer(
                child: Opacity(
                  opacity: (1 - visible * 2.5).clamp(0.0, 1.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleM().copyWith(
                        color: AppColors.textCream,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlassCircle extends StatelessWidget {
  const _GlassCircle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: Center(child: child),
    );
  }
}
