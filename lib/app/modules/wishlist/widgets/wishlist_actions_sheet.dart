import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/show_app_dialog.dart';
import '../../../data/models/wishlist_item.dart';
import '../../../routes/app_routes.dart';
import '../../market/benchmark_detail_controller.dart';
import '../wishlist_controller.dart';
import 'wishlist_row.dart';
import 'wishlist_sheet.dart';

/// What a tapped wishlist row offers: open the bottle, "I bought it", edit
/// the target, or remove it.
Future<void> showWishlistActionsSheet(
  BuildContext context,
  WishlistItem item,
) async {
  final action = await showAppAnimatedBottomSheet<_Action>(
    context: context,
    builder: (ctx) => _ActionsSheet(item: item),
  );
  if (action == null || !context.mounted) return;

  final wishlist = WishlistController.to;
  switch (action) {
    case _Action.open:
      unawaited(
        Get.toNamed(
          AppRoutes.benchmarkDetail,
          arguments: BenchmarkDetailRouteArgs.mapFromBluebook(item.bottle),
        ),
      );
    case _Action.bought:
      await wishlist.markBought(item);
    case _Action.edit:
      await showWishlistSheet(
        context,
        bottleId: item.bottleId,
        name: item.bottle.bottleName,
        average: item.currentPrice,
        low: double.tryParse(item.bottle.low ?? ''),
      );
    case _Action.remove:
      if (await wishlist.remove(item.bottleId, source: 'row_actions')) {
        await AppSnackbar.info('Removed from your wishlist');
      }
  }
}

enum _Action { open, bought, edit, remove }

class _ActionsSheet extends StatelessWidget {
  const _ActionsSheet({required this.item});

  final WishlistItem item;

  @override
  Widget build(BuildContext context) {
    final target = wishlistTargetLabel(item);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.cardSurfaceGradient,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.lg,
          AppSpacing.gutter,
          AppSpacing.md + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.bottle.bottleName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleS().copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              [wishlistPriceLine(item), ?target].join(' · '),
              style: AppTextStyles.bodyS().copyWith(color: AppColors.textWolf),
            ),
            if (item.note != null) ...[
              const SizedBox(height: 4),
              Text(
                item.note!,
                style: AppTextStyles.bodyS().copyWith(
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _ActionRow(
              icon: Icons.open_in_new_rounded,
              label: 'View bottle',
              onTap: () => Navigator.of(context).pop(_Action.open),
            ),
            _ActionRow(
              icon: Icons.shopping_bag_outlined,
              label: 'I bought it',
              gold: true,
              onTap: () => Navigator.of(context).pop(_Action.bought),
            ),
            _ActionRow(
              icon: Icons.track_changes_rounded,
              label: item.targetPrice == null
                  ? 'Set a target price'
                  : 'Edit target and note',
              onTap: () => Navigator.of(context).pop(_Action.edit),
            ),
            _ActionRow(
              icon: Icons.delete_outline_rounded,
              label: 'Remove from wishlist',
              danger: true,
              onTap: () => Navigator.of(context).pop(_Action.remove),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.gold = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool gold;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.marketTrendDown
        : (gold ? AppColors.goldBright : AppColors.textCream);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTextStyles.bodyL().copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
