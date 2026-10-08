import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/animations/staggered_entrance.dart';
import '../../core/platform/app_platform.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../data/models/collection_item_display.dart';
import '../../data/models/collection_item_model.dart';
import 'collection_controller.dart';
import 'widgets/collection_bottle_row.dart';
import 'widgets/collection_filter_row.dart';
import 'widgets/collection_quick_view.dart';

const double _kInset = 23;

/// Every bottle in the collection, from the Collection tab's "View all
/// bottles": the sort menu, the filter chips and one row per bottle, each
/// opening its quick view. Shares [CollectionController] with the tab, so an
/// edit here shows there too.
class CollectionBottlesView extends GetView<CollectionController> {
  const CollectionBottlesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDeep,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDeep,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: AppBackButton(onPressed: () => Get.back<void>()),
        titleSpacing: 0,
        title: Obx(
          () => Text(
            'All bottles (${controller.items.length})',
            style: AppTextStyles.titleM().copyWith(color: AppColors.textCream),
          ),
        ),
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: controller.forceReload,
        child: StaggerScope(
          child: CustomScrollView(
            physics: AppPlatform.scrollPhysics,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  _kInset,
                  AppSpacing.xs,
                  _kInset,
                  18,
                ),
                sliver: SliverToBoxAdapter(
                  child: CollectionFilterRow(controller: controller),
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
                      child: Center(child: _EmptyState(controller: controller)),
                    ),
                  );
                }
                return _List(list: list, controller: controller);
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.list, required this.controller});

  final List<CollectionItemModel> list;
  final CollectionController controller;

  @override
  Widget build(BuildContext context) {
    // Hero tags must be unique on screen; only the first row of a bottle
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
      // An explicit padding drops the automatic inset, so clear Android's
      // navigation bar here.
      padding: EdgeInsets.fromLTRB(
        _kInset,
        0,
        _kInset,
        AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
      ),
      sliver: SliverList.separated(
        itemCount: list.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = list[index];
          final bottleId = item.bluebookBottleId;
          return StaggeredEntrance(
            id: 'collection-${item.id}',
            child: Builder(
              builder: (rowContext) => Obx(
                () => CollectionBottleRow(
                  item: item,
                  heroBottleId: heroIds[index],
                  // Always read the map: an Obx that reads nothing throws.
                  sparkline: controller.sparklines[bottleId ?? ''],
                  onTap: () => showCollectionQuickView(
                    rowContext,
                    item: item,
                    controller: controller,
                  ),
                ),
              ),
            ),
          );
        },
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
      // The last bottle was removed from here: nothing left to list.
      return AppEmptyState(
        icon: Icons.liquor_rounded,
        title: 'Your collection is empty',
        message: 'Bottles you add show up here.',
        actionLabel: 'Back to collection',
        onAction: () => Get.back<void>(),
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
