import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../core/animations/state_switcher.dart';
import '../../core/animations/staggered_entrance.dart';
import '../../core/platform/app_platform.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/shimmer_box.dart';
import 'market_controller.dart';
import 'market_loading_view.dart';
import 'widgets/market_bottle_row.dart';

const double _kInset = 23;

/// The benchmark list: search (typo tolerant, semantic when enabled),
/// category chips, and an infinitely scrolling list of bottles.
class MarketView extends GetView<MarketController> {
  const MarketView({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceDeep,
      child: SafeArea(
        top: false,
        child: Obx(() {
          final loading = controller.isLoading.value;
          return AppStateSwitcher(
            stateKey: loading,
            child: loading ? const MarketLoadingView() : const _MarketList(),
          );
        }),
      ),
    );
  }
}

class _MarketList extends GetView<MarketController> {
  const _MarketList();

  Future<void> _refresh() async {
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(AppAnalyticsController.to.logTap('market_pull_refresh'));
    }
    await controller.forceReload(showFullLoader: false);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 320) {
            controller.loadMore();
          }
          return false;
        },
        child: CustomScrollView(
          physics: AppPlatform.scrollPhysics,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                _kInset,
                kShellTabBodyContentTopGap,
                _kInset,
                14,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => AppSearchField(
                        controller: controller.searchCtrl,
                        onChanged: controller.onSearchChanged,
                        hintText: 'Search 250,000+ bottles',
                        busy: controller.isSearching.value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _CategoryRow(),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(_kInset, 0, _kInset, 24),
              sliver: Obx(() {
                final bottles = controller.visibleBottles;
                // A fresh query / category gets a fresh stagger.
                final listKey = ValueKey(
                  '${controller.keyword.value}|'
                  '${controller.selectedCategoryId.value}',
                );

                if (bottles.isEmpty) {
                  return SliverToBoxAdapter(
                    child: AppStateSwitcher(
                      stateKey: listKey,
                      child: controller.isSearching.value
                          ? const _SkeletonRows()
                          : const _NoBottlesFound(),
                    ),
                  );
                }

                return SliverList.separated(
                  key: listKey,
                  itemCount: bottles.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == bottles.length) {
                      return Obx(
                        () => AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: controller.isLoadingMore.value
                              ? const _SkeletonRows(count: 2)
                              : const SizedBox(height: 8),
                        ),
                      );
                    }
                    return StaggeredEntrance(
                      index: index.clamp(0, 8),
                      child: MarketBottleRow(bottle: bottles[index]),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends GetView<MarketController> {
  const _CategoryRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Obx(
        () => ListView.separated(
          scrollDirection: Axis.horizontal,
          // Chips scroll edge to edge; the selected chip's glow is not
          // clipped into a box.
          clipBehavior: Clip.none,
          padding: const EdgeInsets.only(right: 4),
          itemCount: controller.categories.length + 1,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final isAll = index == 0;
            final label = isAll ? 'All' : controller.categories[index - 1].name;
            final id = isAll ? '' : controller.categories[index - 1].id;
            return AppFilterChip(
              label: label,
              selected: controller.selectedCategoryId.value == id,
              onTap: () {
                if (Get.isRegistered<AppAnalyticsController>()) {
                  unawaited(
                    AppAnalyticsController.to.logTap('market_category_select', {
                      'category_id': id,
                    }),
                  );
                }
                controller.selectCategory(id);
              },
            );
          },
        ),
      ),
    );
  }
}

/// Placeholder rows while the first page of a new query loads, or while the
/// next page arrives at the bottom.
class _SkeletonRows extends StatelessWidget {
  const _SkeletonRows({this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerBox(height: 86, width: double.infinity),
            ),
        ],
      ),
    );
  }
}

/// No results for the current search / category.
class _NoBottlesFound extends GetView<MarketController> {
  const _NoBottlesFound();

  @override
  Widget build(BuildContext context) {
    final searching = controller.keyword.value.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: AppEmptyState(
        icon: searching ? Icons.search_off_rounded : Icons.liquor_rounded,
        title: searching ? 'No bottles found' : 'Nothing in this category',
        message: searching
            ? 'Try a shorter search, or check the spelling of the distillery '
                  'or expression.'
            : 'We have not benchmarked any bottles here yet. Try another '
                  'category.',
        actionLabel: searching ? 'Clear search' : null,
        onAction: searching ? controller.clearSearch : null,
      ),
    );
  }
}
