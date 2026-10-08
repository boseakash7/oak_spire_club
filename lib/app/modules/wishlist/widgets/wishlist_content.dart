import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/animations/staggered_entrance.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/animated_count_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_filter_chip.dart';
import '../../navigation/bottom_nav_controller.dart';
import '../wishlist_controller.dart';
import 'wishlist_actions_sheet.dart';
import 'wishlist_row.dart';

/// The Collection tab's Wishlist view: what the list costs today and how it
/// moved since the bottles were added, the filter chips, and one row per
/// bottle. Tapping a row opens its actions.
class WishlistContent extends StatelessWidget {
  const WishlistContent({super.key, required this.inset});

  /// The tab's side inset.
  final double inset;

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistController.to;
    return Obx(() {
      if (wishlist.isLoading.value && wishlist.items.isEmpty) {
        return const Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(child: CircularProgressIndicator.adaptive()),
        );
      }
      if (wishlist.items.isEmpty) {
        return Padding(
          padding: EdgeInsets.fromLTRB(inset, 48, inset, 0),
          child: AppEmptyState(
            icon: Icons.bookmark_border_rounded,
            title: 'Start your wishlist',
            message:
                'Save bottles you want from Market. Oak Spire tracks their '
                'price from the day you add them, against your target.',
            actionLabel: 'Browse the market',
            onAction: () => Get.find<BottomNavController>().setIndex(
              BottomNavController.marketTab,
            ),
          ),
        );
      }

      final list = wishlist.filteredItems;
      // Read the map here so the rows rebuild as price lines land.
      final sparks = Map.of(wishlist.sparklines);
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: inset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeSlideEntrance(child: _Summary(wishlist: wishlist)),
            const SizedBox(height: AppSpacing.md),
            AppFilterChipBar<WishlistFilter>(
              items: [
                for (final f in WishlistFilter.values)
                  AppFilterChipItem(f, f.label),
              ],
              selected: wishlist.filter.value,
              onSelected: (f) => wishlist.filter.value = f,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  'No bottles here right now.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyM().copyWith(
                    color: AppColors.textWolf,
                  ),
                ),
              ),
            for (final (i, item) in list.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              StaggeredEntrance(
                id: 'wishlist-${item.bottleId}',
                child: Builder(
                  builder: (rowContext) => WishlistRow(
                    item: item,
                    heroId: item.bottleId,
                    sparkline: sparks[item.bottleId],
                    onTap: () => showWishlistActionsSheet(rowContext, item),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.wishlist});

  final WishlistController wishlist;

  @override
  Widget build(BuildContext context) {
    final change = wishlist.changeSinceAdded;
    final atTarget = wishlist.atTargetCount;
    final near = wishlist.nearTargetCount;
    final muted = AppTextStyles.bodyS().copyWith(color: AppColors.textMuted);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your wishlist · ${wishlist.items.length} '
            '${wishlist.items.length == 1 ? 'bottle' : 'bottles'}',
            style: muted,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AnimatedCountText(
                  value: wishlist.totalNow,
                  style: AppTextStyles.numberM(),
                  format: (v) => PriceFormatter.format(v.round().toString()),
                ),
              ),
              if (change != null)
                Text(
                  '${PriceFormatter.percentLabel(change)} since added',
                  style: AppTextStyles.bodyS().copyWith(
                    fontWeight: FontWeight.w600,
                    color: PriceFormatter.percentColor(change),
                  ),
                ),
            ],
          ),
          Text('At today\'s market prices', style: muted.copyWith(fontSize: 11)),
          if (atTarget > 0 || near > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (atTarget > 0)
                  WishlistTargetChip(label: '$atTarget at target', met: true),
                if (near > 0)
                  WishlistTargetChip(
                    label: '$near within 10% of target',
                    met: false,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
