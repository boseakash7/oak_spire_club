import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../core/animations/state_switcher.dart';
import '../../core/animations/staggered_entrance.dart';
import '../../core/platform/app_platform.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_search_field.dart';
import 'market_controller.dart';
import 'market_loading_view.dart';
import 'widgets/market_bottle_row.dart';
import 'widgets/market_index_strip.dart';
import 'widgets/market_sort_button.dart';

const double _kInset = 23;

/// The Market tab: the Oak Spire indexes, then search
/// (typo tolerant, semantic when enabled), category chips, a sort, and an
/// infinitely scrolling list of bottles.
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
            const SliverToBoxAdapter(
              child: SizedBox(height: kShellTabBodyContentTopGap),
            ),
            // The market at a glance: the indexes. Hidden while searching,
            // when the list is what the user is after.
            Obx(
              () => SliverToBoxAdapter(
                child: controller.keyword.value.trim().isNotEmpty
                    ? const SizedBox.shrink()
                    : const MarketIndexStrip(inset: _kInset),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(_kInset, 0, _kInset, 14),
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Obx(() {
                            final updated = controller.lastUpdatedText.value;
                            if (updated.isEmpty) return const SizedBox.shrink();
                            return Text(
                              'Prices ${updated[0].toLowerCase()}${updated.substring(1)}',
                              style: AppTextStyles.bodyS().copyWith(
                                fontSize: 11,
                                color: AppColors.textWolf,
                              ),
                            );
                          }),
                        ),
                        const MarketSortButton(),
                      ],
                    ),
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
                  '${controller.selectedCategoryId.value}|'
                  '${controller.sort.value.name}',
                );

                if (bottles.isEmpty) {
                  return SliverToBoxAdapter(
                    child: AppStateSwitcher(
                      stateKey: listKey,
                      child: controller.isSearching.value
                          ? const MarketBottleSkeletonList()
                          : const _NoBottlesFound(),
                    ),
                  );
                }

                // Rows that scroll in after the first screenful show at rest.
                return StaggerScope(
                  key: listKey,
                  entranceWindow: const Duration(milliseconds: 600),
                  child: SliverList.separated(
                    itemCount: bottles.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == bottles.length) {
                        return Obx(
                          () => AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: controller.isLoadingMore.value
                                ? const MarketBottleSkeletonList(count: 2)
                                : const SizedBox(height: 8),
                          ),
                        );
                      }
                      final bottle = bottles[index];
                      return StaggeredEntrance(
                        id: bottle.id,
                        child: Obx(
                          () => MarketBottleRow(
                            bottle: bottle,
                            sparkline: controller.sparklines[bottle.id],
                          ),
                        ),
                      );
                    },
                  ),
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
    return Obx(
      () => AppFilterChipBar<String>(
        items: [
          const AppFilterChipItem('', 'All'),
          for (final c in controller.categories)
            AppFilterChipItem(c.id, c.name),
        ],
        selected: controller.selectedCategoryId.value,
        onSelected: (id) {
          if (Get.isRegistered<AppAnalyticsController>()) {
            unawaited(
              AppAnalyticsController.to.logTap('market_category_select', {
                'category_id': id,
              }),
            );
          }
          controller.selectCategory(id);
        },
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
