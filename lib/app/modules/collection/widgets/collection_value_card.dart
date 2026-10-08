import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_count_text.dart';
import '../../../core/widgets/app_card.dart';
import '../collection_controller.dart';

final _wholeDollars = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 0,
);

/// "Collection value", a full-width card titled inside like the app's other
/// cards: today's worth counting up, what was paid and the gain beneath it,
/// and the gain against paid as a percentage.
class CollectionValueCard extends StatelessWidget {
  const CollectionValueCard({super.key, required this.controller});

  final CollectionController controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // The heading has to match the number: with no market price
                // anywhere in the collection, the number is what was paid.
                Obx(
                  () => Text(
                    controller.showingInvestedAsValue.value
                        ? 'Total invested'
                        : 'Collection value',
                    style: AppTextStyles.bodyS().copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => AppTextStyles
                      .collectionValueGradient
                      .createShader(bounds),
                  child: Obx(
                    () => AnimatedCountText(
                      value: controller.valueAmount.value,
                      format: (v) => v <= 0 ? r'$ —' : _wholeDollars.format(v),
                      style: AppTextStyles.button20Bold().copyWith(
                        fontSize: 28,
                        height: 1.12,
                      ),
                    ),
                  ),
                ),
                Obx(() {
                  final caption = controller.valueCaption.value;
                  if (caption.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Obx(() {
            final pct = controller.gainPercent.value;
            return AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.medium),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: _GainBadge(
                key: ValueKey(controller.trendShort.value),
                percent: pct,
                label: controller.trendShort.value,
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Gain against what was paid, green when up and red when down. Gold with
/// the chart glyph while there is no figure yet.
class _GainBadge extends StatelessWidget {
  const _GainBadge({super.key, required this.percent, required this.label});

  final double? percent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final pct = percent;
    final tint = pct == null
        ? AppColors.goldBright
        : pct >= 0
        ? AppColors.trendPositive
        : AppColors.trendNegative;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: pct == null
            ? AppColors.goldAccentGlow
            : tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: pct == null
              ? AppColors.tagGoldBorder
              : tint.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pct == null)
            SvgPicture.asset(
              AppAssets.collectionTrendChart,
              width: 22,
              height: 11,
              fit: BoxFit.contain,
            )
          else
            SvgPicture.asset(
              pct >= 0 ? AppAssets.iconArrowUp : AppAssets.iconArrowDown,
              width: 11,
              height: 11,
              colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodyL().copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tint,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
