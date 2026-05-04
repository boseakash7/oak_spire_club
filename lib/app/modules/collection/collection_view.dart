import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/collection_item_display.dart';
import '../../data/models/collection_item_model.dart';
import 'collection_controller.dart';
import 'collection_loading_view.dart';

const double _kCollectionCardRadius = 20;
const double _kFabSize = 60;
const double _kFigmaCardW = 166;
const double _kFigmaCardH = 211;
const double _kFigmaBottleImage = 100;

class CollectionView extends GetView<CollectionController> {
  const CollectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const CollectionLoadingView();
      }
      final bottomPad = MediaQuery.paddingOf(context).bottom;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          _CollectionBody(controller: controller),
          Positioned(
            right: 16,
            bottom: 24 + bottomPad,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {},
                child: Ink(
                  width: _kFabSize,
                  height: _kFabSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.goldRich,
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowBlack32,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.add, color: AppColors.white, size: 32),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _CollectionBody extends StatelessWidget {
  const _CollectionBody({required this.controller});

  final CollectionController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surfaceDeep, AppColors.surfaceDeep],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(color: AppColors.overlayBlack20),
          ),
          SafeArea(
            top: false,
            child: RefreshIndicator(
              color: AppColors.gold1,
              onRefresh: controller.load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(23, 108, 23, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ValueHeader(controller: controller),
                          const SizedBox(height: 18),
                          _FilterRow(controller: controller),
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
                          padding: const EdgeInsets.fromLTRB(23, 24, 23, 120),
                          child: Center(
                            child: Text(
                              controller.items.isEmpty
                                  ? 'Your collection is empty.'
                                  : 'No bottles match this filter.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body16().copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(23, 0, 23, 120),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 14,
                              childAspectRatio: _kFigmaCardW / _kFigmaCardH,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _BottleCard(item: list[index]);
                        }, childCount: list.length),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueHeader extends StatelessWidget {
  const _ValueHeader({required this.controller});

  final CollectionController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Collection Value',
                style: AppTextStyles.body16().copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textCream,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.gold2, AppColors.gold1],
                    stops: [0.21591, 0.90909],
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    controller.valueText.value,
                    style: AppTextStyles.button20Bold().copyWith(
                      fontSize: 28,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              AppAssets.collectionTrendChart,
              width: 22,
              height: 11,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            Obx(
              () => Text(
                controller.trendShort.value,
                style: AppTextStyles.body16().copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldBright,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.controller});

  final CollectionController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Icon(
            Icons.filter_list_rounded,
            size: 28,
            color: AppColors.textCream.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(
              () => ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.only(right: 4),
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: controller.filter.value == CollectionFilter.all,
                    onTap: () => controller.setFilter(CollectionFilter.all),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'Opened',
                    selected:
                        controller.filter.value == CollectionFilter.opened,
                    onTap: () => controller.setFilter(CollectionFilter.opened),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'Not opened',
                    selected:
                        controller.filter.value == CollectionFilter.notOpened,
                    onTap: () =>
                        controller.setFilter(CollectionFilter.notOpened),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'Rare Find',
                    selected:
                        controller.filter.value == CollectionFilter.rareFind,
                    onTap: () =>
                        controller.setFilter(CollectionFilter.rareFind),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(42),
        child: Container(
          height: 28,
          constraints: const BoxConstraints(minWidth: 92),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(42),
            gradient: selected
                ? AppColors.goldGradient
                : AppColors.cardSurfaceGradient,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.body16().copyWith(
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              color: selected ? AppColors.white : AppColors.textCream,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottleCard extends StatelessWidget {
  const _BottleCard({required this.item});

  final CollectionItemModel item;

  @override
  Widget build(BuildContext context) {
    final url = item.resolvedImageUrl;
    final ratio = item.fillRatio;
    Widget bottlePlaceholder() =>
        Image.asset(AppAssets.collectionBottlePlaceholder, fit: BoxFit.contain);

    return ClipRRect(
      borderRadius: BorderRadius.circular(_kCollectionCardRadius),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.cardSurfaceGradient,
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final scale = w / _kFigmaCardW;
            final imageSide = _kFigmaBottleImage * scale;
            final padH = 15 * scale;
            final topPad = 16 * scale;
            final barW = 63 * scale;
            final fillW = (barW * ratio).clamp(4.0, barW);
            final radiusImg = 8 * scale;

            return Padding(
              padding: EdgeInsets.fromLTRB(padH, topPad, padH, 10 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radiusImg),
                      child: SizedBox(
                        width: imageSide,
                        height: imageSide,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppColors.bottleRadialGlow,
                              ),
                            ),
                            if (url != null)
                              Image.network(
                                url,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: SizedBox(
                                      width: 22 * scale,
                                      height: 22 * scale,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.gold1.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    bottlePlaceholder(),
                              )
                            else
                              bottlePlaceholder(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14 * scale),
                  Text(
                    item.lineTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body16().copyWith(
                      fontSize: 12,
                      height: 1.2,
                      color: AppColors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (item.lineSubtitle.isNotEmpty) ...[
                    Text(
                      item.lineSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body16().copyWith(
                        fontSize: 12,
                        height: 1.2,
                        color: AppColors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  SizedBox(
                    height: item.lineSubtitle.isEmpty ? 6 * scale : 4 * scale,
                  ),
                  Text(
                    item.proofLabel,
                    style: AppTextStyles.body16().copyWith(
                      fontSize: 10,
                      color: AppColors.textWolf,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          item.priceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body16().copyWith(
                            fontSize: 12,
                            color: AppColors.textCream,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: barW,
                            height: 8 * scale,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.fillBarTrack,
                                    borderRadius: BorderRadius.circular(
                                      27 * scale,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: fillW,
                                    height: 8 * scale,
                                    decoration: BoxDecoration(
                                      color: AppColors.goldRich,
                                      borderRadius: BorderRadius.circular(
                                        27 * scale,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
