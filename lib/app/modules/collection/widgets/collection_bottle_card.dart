import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_fill_bar.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/bottle_image.dart';
import '../../../data/models/collection_item_display.dart';
import '../../../data/models/collection_item_model.dart';

/// Figma card geometry (166 × 211); the card scales from it.
const double kCollectionCardWidth = 166;
const double kCollectionCardHeight = 211;
const double kCollectionCardRadius = 20;
const double kCollectionBottleImage = 100;

/// One bottle in the collection grid: art, name, proof, price × quantity and
/// how full it is. Presses scale it; [heroBottleId] lets its art fly to the
/// quick view and the detail screen.
class CollectionBottleCard extends StatelessWidget {
  const CollectionBottleCard({
    super.key,
    required this.item,
    required this.onTap,
    this.heroBottleId,
  });

  final CollectionItemModel item;
  final VoidCallback onTap;

  /// Null when another card on screen already uses this bottle's Hero tag.
  final String? heroBottleId;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: PressHaptic.tap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kCollectionCardRadius),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: AppColors.cardSurfaceGradient,
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final scale = c.maxWidth / kCollectionCardWidth;
              final imageSide = kCollectionBottleImage * scale;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  15 * scale,
                  16 * scale,
                  15 * scale,
                  10 * scale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8 * scale),
                        child: SizedBox.square(
                          dimension: imageSide,
                          child: BottleImage(
                            urls: item.resolvedImageCandidates,
                            bottleId: heroBottleId,
                            cacheWidthPx:
                                (imageSide *
                                        MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 14 * scale),
                    CollectionCardDetails(item: item, scale: scale),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            item.priceLabelWithQuantity,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyL().copyWith(
                              fontSize: 12,
                              color: AppColors.textCream,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 63 * scale,
                          child: AnimatedFillBar(
                            value: item.fillRatio,
                            height: 8 * scale,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Name, optional subtitle and proof — shared by the card and its quick view.
class CollectionCardDetails extends StatelessWidget {
  const CollectionCardDetails({super.key, required this.item, this.scale = 1});

  final CollectionItemModel item;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.lineTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.uiCardTitle(),
        ),
        if (item.lineSubtitle.isNotEmpty)
          Text(
            item.lineSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.uiCardTitle(),
          ),
        SizedBox(height: (item.lineSubtitle.isEmpty ? 6 : 4) * scale),
        Text(item.proofLabel, style: AppTextStyles.uiCardMeta()),
      ],
    );
  }
}
