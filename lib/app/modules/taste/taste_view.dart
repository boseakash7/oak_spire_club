import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/animations/state_switcher.dart';
import '../../core/animations/staggered_entrance.dart';
import '../../core/platform/app_platform.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_image_url.dart';
import '../../core/utils/price_formatter.dart';
import '../../core/utils/proof_formatter.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/bottle_image.dart';
import '../../core/widgets/pricing_badge.dart';
import '../../data/models/bluebook_model.dart';
import '../../routes/app_routes.dart';
import '../collection/collection_controller.dart';
import '../home/home_controller.dart';
import '../navigation/bottom_nav_controller.dart';
import 'taste_controller.dart';
import 'taste_loading_view.dart';

const double _kInset = 23;

/// Height of [_AddOwnBottleRow] including its top margin.
const double _kAddOwnRowExtent = 72;

/// "Add a bottle": search the catalog, tap a bottle to add it, or add one
/// that is not listed.
class TasteView extends GetView<TasteController> {
  const TasteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDeep,
      appBar: AppScreenAppBar(
        centerTitle: false,
        title: Text(
          'Add a bottle',
          style: AppTextStyles.headingM().copyWith(color: AppColors.textCream),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final loading = controller.isLoading.value;
          return AppStateSwitcher(
            stateKey: loading,
            child: loading ? const TasteLoadingView() : const _TasteList(),
          );
        }),
      ),
    );
  }
}

/// After a bottle is added: land on the Collection tab with fresh data.
Future<void> _handleAddedSuccess() async {
  if (Get.isRegistered<BottomNavController>()) {
    Get.find<BottomNavController>().setIndex(1);
  }
  if (Get.isRegistered<CollectionController>()) {
    await Get.find<CollectionController>().forceReload();
  }
  if (Get.isRegistered<HomeController>()) {
    unawaited(Get.find<HomeController>().forceReload());
  }
  if (Get.key.currentState?.canPop() ?? false) {
    Get.back(result: true);
  }
}

class _TasteList extends GetView<TasteController> {
  const _TasteList();

  Future<void> _add(BluebookModel bottle) async {
    final res = await controller.addBottleToCollection(bottle);
    if (res == true) await _handleAddedSuccess();
  }

  Future<void> _addOwn() async {
    final res = await Get.toNamed(AppRoutes.addToCollection);
    if (res == true) await _handleAddedSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: () => controller.forceReload(showFullLoader: false),
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
              padding: const EdgeInsets.fromLTRB(_kInset, 8, _kInset, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Obx(
                      () => AppSearchField(
                        controller: controller.searchCtrl,
                        onChanged: controller.onSearchChanged,
                        hintText: 'Search bottles by name or distillery',
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
              padding: const EdgeInsets.symmetric(horizontal: _kInset),
              sliver: Obx(() {
                final bottles = controller.visibleBottles;
                if (bottles.isEmpty) {
                  return SliverToBoxAdapter(
                    child: controller.isSearching.value
                        ? const TasteBottleSkeletonList()
                        : Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: AppEmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No bottles found',
                              message:
                                  'Try another spelling, or add it yourself '
                                  'below.',
                              actionLabel:
                                  controller.keyword.value.trim().isEmpty
                                  ? null
                                  : 'Clear search',
                              onAction: controller.clearSearch,
                            ),
                          ),
                  );
                }
                return SliverList.separated(
                  key: ValueKey(
                    '${controller.keyword.value}|'
                    '${controller.selectedCategoryId.value}',
                  ),
                  itemCount: bottles.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) => StaggeredEntrance(
                    index: index.clamp(0, 8),
                    child: _BottleRow(
                      bottle: bottles[index],
                      onAdd: () => _add(bottles[index]),
                    ),
                  ),
                );
              }),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(_kInset, 10, _kInset, 0),
              sliver: SliverToBoxAdapter(
                child: Obx(
                  () => controller.isLoadingMore.value
                      ? const TasteBottleSkeletonList(count: 2)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(_kInset, 0, _kInset, 32),
              // Only offered when the results don't fill the screen or there
              // are none; a long list keeps the user browsing instead.
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final fitsOnScreen =
                      constraints.precedingScrollExtent + _kAddOwnRowExtent <=
                      constraints.viewportMainAxisExtent;
                  return Obx(() {
                    final hasResults = controller.visibleBottles.isNotEmpty;
                    final busy =
                        controller.isSearching.value ||
                        controller.isLoadingMore.value;
                    final show = !busy && (!hasResults || fitsOnScreen);
                    return SliverToBoxAdapter(
                      child: show
                          ? FadeSlideEntrance(
                              child: _AddOwnBottleRow(onTap: _addOwn),
                            )
                          : const SizedBox.shrink(),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends GetView<TasteController> {
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
              onTap: () => controller.selectCategory(id),
            );
          },
        ),
      ),
    );
  }
}

class _BottleRow extends StatelessWidget {
  const _BottleRow({required this.bottle, required this.onAdd});

  final BluebookModel bottle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onAdd,
      haptic: PressHaptic.tap,
      semanticLabel: 'Add ${bottle.bottleName}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 8, 10, 8),
        decoration: BoxDecoration(
          gradient: AppColors.cardSurfaceGradient,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox.square(
                dimension: 56,
                child: BottleImage(
                  url: AppImageUrl.resolve(bottle.image),
                  cacheWidthPx: 170,
                  padding: const EdgeInsets.all(3),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bottle.bottleName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyM().copyWith(
                      fontSize: 14,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ProofFormatter.formatLabelOrFallback(bottle.proof),
                    style: AppTextStyles.bodyS().copyWith(
                      fontSize: 10,
                      color: AppColors.textWolf,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if ((double.tryParse(bottle.average ?? '') ?? 0) <= 0)
                  Text(
                    'No price yet',
                    style: AppTextStyles.bodyS().copyWith(
                      fontSize: 10,
                      color: AppColors.textWolf,
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PricingBadge(pricing: bottle.pricing, compact: true),
                      const SizedBox(width: 5),
                      Text(
                        PriceFormatter.format(bottle.average),
                        style: AppTextStyles.bodyM().copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textCream,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.goldGradient,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOwnBottleRow extends StatelessWidget {
  const _AddOwnBottleRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: PressHaptic.tap,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.tagGoldBorder),
          color: AppColors.goldAccentGlow,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.black),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add your own bottle',
                    style: AppTextStyles.bodyL().copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Not in the list? Enter it yourself.',
                    style: AppTextStyles.bodyS().copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
