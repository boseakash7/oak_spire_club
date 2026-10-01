import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../core/animations/app_motion.dart';
import '../../core/animations/state_switcher.dart';
import '../../core/animations/staggered_entrance.dart';
import '../../core/constants/app_assets.dart';
import '../../core/platform/app_platform.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_pressable.dart';
import '../../data/models/collection_item_display.dart';
import '../../data/models/collection_item_model.dart';
import '../../routes/app_routes.dart';
import 'collection_controller.dart';
import 'collection_loading_view.dart';
import 'widgets/collection_bottle_card.dart';
import 'widgets/collection_filter_row.dart';
import 'widgets/collection_quick_view.dart';
import 'widgets/collection_value_header.dart';

const double _kInset = 23;

class CollectionView extends GetView<CollectionController> {
  const CollectionView({super.key});

  @override
  Widget build(BuildContext context) {
    _precachePlaceholder(context);
    return Obx(() {
      final loading = controller.isLoading.value;
      return AppStateSwitcher(
        stateKey: loading,
        child: loading
            ? const CollectionLoadingView()
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  _CollectionBody(controller: controller),
                  Positioned(
                    right: 16,
                    bottom: 24 + MediaQuery.paddingOf(context).bottom,
                    child: _AddBottleFab(controller: controller),
                  ),
                ],
              ),
      );
    });
  }

  static bool _precached = false;

  static void _precachePlaceholder(BuildContext context) {
    if (_precached) return;
    _precached = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage(AppAssets.collectionBottlePlaceholder),
        context,
      );
    });
  }
}

class _CollectionBody extends StatelessWidget {
  const _CollectionBody({required this.controller});

  final CollectionController controller;

  Future<void> _refresh() async {
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(AppAnalyticsController.to.logTap('collection_pull_refresh'));
    }
    await controller.forceReload();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceDeep,
      child: SafeArea(
        top: false,
        child: RefreshIndicator.adaptive(
          onRefresh: _refresh,
          child: StaggerScope(
            child: CustomScrollView(
              physics: AppPlatform.scrollPhysics,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    _kInset,
                    kShellTabBodyContentTopGap,
                    _kInset,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeSlideEntrance(
                          child: CollectionValueHeader(controller: controller),
                        ),
                        const SizedBox(height: 18),
                        FadeSlideEntrance(
                          index: 1,
                          child: CollectionFilterRow(controller: controller),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
                Obx(() {
                  final list = controller.filteredItems;
                  if (list.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          _kInset,
                          8,
                          _kInset,
                          120,
                        ),
                        child: Center(
                          child: _EmptyState(controller: controller),
                        ),
                      ),
                    );
                  }
                  return _Grid(list: list, controller: controller);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.list, required this.controller});

  final List<CollectionItemModel> list;
  final CollectionController controller;

  @override
  Widget build(BuildContext context) {
    // Hero tags must be unique on screen; only the first card of a bottle
    // carries one.
    final seen = <String>{};
    final heroIds = [
      for (final item in list)
        () {
          final id = item.bluebookBottleId;
          return id != null && seen.add(id) ? id : null;
        }(),
    ];

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(_kInset, 0, _kInset, 120),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: 14,
          childAspectRatio: kCollectionCardWidth / kCollectionCardHeight,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = list[index];
          return StaggeredEntrance(
            id: 'collection-${item.id}',
            child: Builder(
              builder: (cardContext) => CollectionBottleCard(
                item: item,
                heroBottleId: heroIds[index],
                onTap: () => showCollectionQuickView(
                  cardContext,
                  item: item,
                  controller: controller,
                ),
              ),
            ),
          );
        }, childCount: list.length),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.controller});

  final CollectionController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.items.isEmpty) {
      // An empty collection is the moment a user is most likely to bounce,
      // so send them straight to the bottle browser.
      return AppEmptyState(
        icon: Icons.liquor_rounded,
        title: 'Your collection is empty',
        message:
            'Add your first bottle and Oak Spire will track what it is worth '
            'against the BSMI benchmark.',
        actionLabel: 'Browse bottles',
        onAction: () async {
          final res = await Get.toNamed(AppRoutes.tasteBottles);
          if (res == true) await controller.forceReload();
        },
      );
    }

    return AppEmptyState(
      icon: Icons.filter_alt_off_rounded,
      title: 'No bottles match this filter',
      message:
          'Clear the filter to see all ${controller.items.length} bottles in '
          'your collection.',
      actionLabel: 'Clear filter',
      onAction: controller.clearFilter,
    );
  }
}

/// Gold "+" button: pops in when the tab appears and spins a quarter turn
/// on press.
class _AddBottleFab extends StatefulWidget {
  const _AddBottleFab({required this.controller});

  final CollectionController controller;

  @override
  State<_AddBottleFab> createState() => _AddBottleFabState();
}

class _AddBottleFabState extends State<_AddBottleFab> {
  static const double _size = 60;
  double _turns = 0;

  Future<void> _onTap() async {
    setState(() => _turns += 0.25);
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(AppAnalyticsController.to.logTap('collection_add_bottle_fab'));
    }
    final res = await Get.toNamed(AppRoutes.tasteBottles);
    if (res == true) await widget.controller.forceReload();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, AppMotion.slow),
      curve: AppMotion.emphasized,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: AppPressable(
        onTap: _onTap,
        haptic: PressHaptic.tap,
        scale: 0.9,
        semanticLabel: 'Add a bottle',
        child: Container(
          width: _size,
          height: _size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.goldGradient,
            boxShadow: AppShadows.fab,
          ),
          child: AnimatedRotation(
            turns: _turns,
            duration: AppMotion.of(context, AppMotion.medium),
            curve: AppMotion.emphasized,
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.black,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
