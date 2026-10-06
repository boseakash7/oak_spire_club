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
import '../../core/widgets/bottle_meta_chip.dart';
import '../../core/widgets/pricing_badge.dart';
import '../../core/widgets/show_app_dialog.dart';
import '../../data/models/bluebook_model.dart';
import '../../routes/app_routes.dart';
import '../collection/collection_controller.dart';
import '../home/home_controller.dart';
import '../navigation/bottom_nav_controller.dart';
import 'taste_controller.dart';
import 'taste_loading_view.dart';

const double _kInset = 23;

/// Fixed thumbnail slot: every bottle gets the same box and crop.
const double _kThumb = 48;

/// Height of [_AddOwnBottleRow] including its top margin.
const double _kAddOwnRowExtent = 72;

/// Rows built this soon after a list appears play their entrance.
const Duration _kEntranceWindow = Duration(milliseconds: 600);

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
    Get.find<BottomNavController>().setIndex(BottomNavController.collectionTab);
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

  /// Row tap: confirm first, then the usual add flow.
  Future<void> _open(BuildContext context, BluebookModel bottle) async {
    final confirmed = await _showConfirmSheet(
      context,
      bottle: bottle,
      owned: controller.isOwned(bottle),
    );
    if (confirmed != true) return;
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
                        hintText: 'Search name, distillery, or age',
                        busy: controller.isSearching.value,
                      ),
                    ),
                    const _RecentSearches(),
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
                  return SliverToBoxAdapter(child: _emptyBody());
                }
                // A fresh query / category gets a fresh entrance; rows that
                // scroll in later show at rest.
                return StaggerScope(
                  key: ValueKey(
                    '${controller.keyword.value}|'
                    '${controller.selectedCategoryId.value}',
                  ),
                  entranceWindow: _kEntranceWindow,
                  child: SliverList.separated(
                    itemCount: bottles.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final bottle = bottles[index];
                      return StaggeredEntrance(
                        id: bottle.id,
                        child: Obx(
                          () => _BottleRow(
                            bottle: bottle,
                            owned: controller.isOwned(bottle),
                            onTap: () => _open(context, bottle),
                          ),
                        ),
                      );
                    },
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

  /// Nothing to list: still loading, failed, or nothing matched.
  Widget _emptyBody() {
    if (controller.isSearching.value) return const TasteBottleSkeletonList();
    if (controller.loadFailed.value) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: AppEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Couldn’t load bottles',
          message: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => controller.forceReload(showFullLoader: false),
        ),
      );
    }
    final query = controller.keyword.value.trim();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: AppEmptyState(
        icon: Icons.search_off_rounded,
        title: query.isEmpty ? 'No bottles found' : 'No match for “$query”',
        message: 'Try the distillery name or add it manually.',
        actionLabel: query.isEmpty ? null : 'Clear search',
        onAction: controller.clearSearch,
      ),
    );
  }
}

/// Recent queries under an empty search field.
class _RecentSearches extends GetView<TasteController> {
  const _RecentSearches();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller.searchCtrl,
      builder: (context, value, _) {
        return Obx(() {
          final recents = controller.recentSearches.toList(growable: false);
          final show = value.text.isEmpty && recents.isNotEmpty;
          return AnimatedSize(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            child: !show
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: recents.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: AppSpacing.xs),
                              itemBuilder: (context, index) => _RecentChip(
                                label: recents[index],
                                onTap: () =>
                                    controller.searchNow(recents[index]),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        AppPressable(
                          onTap: controller.clearRecentSearches,
                          semanticLabel: 'Clear recent searches',
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xxs),
                            child: Text(
                              'Clear',
                              style: AppTextStyles.bodyS().copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        });
      },
    );
  }
}

class _RecentChip extends StatelessWidget {
  const _RecentChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      semanticLabel: 'Search $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceChip,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(color: AppColors.tagInactiveBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.xxs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyS().copyWith(
                  color: AppColors.textCream,
                ),
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
    return Obx(
      () => AppFilterChipBar<String>(
        items: [
          const AppFilterChipItem('', 'All'),
          for (final c in controller.categories)
            AppFilterChipItem(c.id, c.name),
        ],
        selected: controller.selectedCategoryId.value,
        onSelected: controller.selectCategory,
      ),
    );
  }
}

/// One bottle: name (2 lines), a meta line of chips, a price or nothing, and
/// an "Add" label. The whole row is the tap target.
class _BottleRow extends StatelessWidget {
  const _BottleRow({
    required this.bottle,
    required this.owned,
    required this.onTap,
  });

  final BluebookModel bottle;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPrice = (double.tryParse(bottle.average ?? '') ?? 0) > 0;
    return AppPressable(
      onTap: onTap,
      haptic: PressHaptic.tap,
      semanticLabel: owned
          ? '${bottle.bottleName}, in your collection'
          : 'Add ${bottle.bottleName}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        decoration: BoxDecoration(
          gradient: AppColors.cardSurfaceGradient,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            _BottleThumb(image: bottle.image),
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
                  _MetaChips(bottle: bottle),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasPrice) ...[
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
                  const SizedBox(height: 6),
                ],
                _RowAction(owned: owned),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Same box and crop for every bottle; the bottle placeholder shows until
/// (or instead of) the photo.
class _BottleThumb extends StatelessWidget {
  const _BottleThumb({required this.image, this.size = _kThumb});

  final String? image;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: size,
        child: BottleImage(
          url: AppImageUrl.resolve(image),
          cacheWidthPx: (size * 3).round(),
          padding: const EdgeInsets.all(3),
        ),
      ),
    );
  }
}

/// Age and ABV (proof when the catalog has no ABV) and a Rare tag, as labelled
/// chips: `12 yr · 45%`. Nothing at all when the bottle has none of them,
/// rather than a dash.
class _MetaChips extends StatelessWidget {
  const _MetaChips({required this.bottle});

  final BluebookModel bottle;

  @override
  Widget build(BuildContext context) {
    final details = bottle.details;
    final labels = [
      ?details.ageLabel,
      ?(details.abvLabel ?? ProofFormatter.formatLabel(bottle.proof)),
    ];
    final rare = bottle.isRare == true;
    if (labels.isEmpty && !rare) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final label in labels) BottleMetaChip(label: label),
          if (rare) const BottleMetaChip(label: 'Rare', gold: true),
        ],
      ),
    );
  }
}

/// "Add" as a labelled text button, or the owned marker. Not a gesture of
/// its own: the row beneath handles the tap.
class _RowAction extends StatelessWidget {
  const _RowAction({required this.owned});

  final bool owned;

  @override
  Widget build(BuildContext context) {
    if (owned) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: AppColors.successLight,
          ),
          const SizedBox(width: 4),
          Text(
            'In your collection',
            style: AppTextStyles.bodyS().copyWith(
              fontSize: 11,
              color: AppColors.successLight,
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.add_rounded, size: 16, color: AppColors.goldRich),
        const SizedBox(width: 2),
        Text(
          'Add',
          style: AppTextStyles.bodyM().copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.goldRich,
          ),
        ),
      ],
    );
  }
}

/// The confirm step: a summary of the bottle, then on to the add form.
/// Resolves true when the user chose to continue.
Future<bool?> _showConfirmSheet(
  BuildContext context, {
  required BluebookModel bottle,
  required bool owned,
}) {
  final hasPrice = (double.tryParse(bottle.average ?? '') ?? 0) > 0;
  return showAppAnimatedBottomSheet<bool>(
    context: context,
    builder: (ctx) {
      final bottomInset = MediaQuery.paddingOf(ctx).bottom;
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppColors.cardSurfaceGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(_kInset, 22, _kInset, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _BottleThumb(image: bottle.image, size: 72),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bottle.bottleName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleS().copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        _MetaChips(bottle: bottle),
                        if (hasPrice) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              PricingBadge(
                                pricing: bottle.pricing,
                                compact: true,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                PriceFormatter.format(bottle.average),
                                style: AppTextStyles.bodyM().copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textCream,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (owned) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'This bottle is already in your collection. Continuing '
                  'lets you edit it.',
                  style: AppTextStyles.bodyS().copyWith(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SheetButton(
                      label: 'Cancel',
                      outlined: true,
                      onTap: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: _SheetButton(
                      label: owned ? 'Edit in collection' : 'Add to collection',
                      onTap: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: PressHaptic.tap,
      child: Container(
        height: AppButtonSize.regular,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: outlined ? null : AppColors.goldGradient,
          color: outlined ? AppColors.surfaceChip : null,
          border: outlined
              ? Border.all(color: AppColors.tagInactiveBorder)
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyL().copyWith(
            fontWeight: FontWeight.w700,
            color: outlined ? AppColors.textCream : AppColors.black,
          ),
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
