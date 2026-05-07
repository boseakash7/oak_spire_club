import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/network/app_cache_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/collection_item_display.dart';
import '../../data/models/collection_item_model.dart';
import '../../routes/app_routes.dart';
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
    _CollectionAssetPrecache.ensure(context);
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
                onTap: () async {
                  final res = await Get.toNamed(AppRoutes.addToCollection);
                  if (res == true) {
                    await controller.forceReload();
                  }
                },
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

class _CollectionAssetPrecache {
  _CollectionAssetPrecache._();
  static bool _done = false;

  static void ensure(BuildContext context) {
    if (_done) return;
    _done = true;
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
              onRefresh: controller.forceReload,
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

class _FilterRow extends StatefulWidget {
  const _FilterRow({required this.controller});

  final CollectionController controller;

  @override
  State<_FilterRow> createState() => _FilterRowState();
}

class _FilterRowState extends State<_FilterRow> {
  final _link = LayerLink();
  OverlayEntry? _entry;
  bool _open = false;

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
    if (_open) setState(() => _open = false);
  }

  void _toggle() {
    if (_entry != null) {
      _hide();
      return;
    }

    setState(() => _open = true);
    _entry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _hide,
                behavior: HitTestBehavior.translucent,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: const Offset(41, 0),
              child: _SortMenu(controller: widget.controller, onClose: _hide),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          CompositedTransformTarget(
            link: _link,
            child: Obx(
              () => InkResponse(
                onTap: _toggle,
                radius: 24,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SvgPicture.asset(
                      AppAssets.collectionFilterIcon,
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textMuted,
                        BlendMode.srcIn,
                      ),
                    ),
                    if (widget.controller.hasActiveSort)
                      const Positioned(
                        right: -2,
                        top: -2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(width: 9, height: 9),
                        ),
                      ),
                  ],
                ),
              ),
            ),
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
                    selected:
                        widget.controller.filter.value == CollectionFilter.all,
                    onTap: () =>
                        widget.controller.setFilter(CollectionFilter.all),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'Opened',
                    selected:
                        widget.controller.filter.value ==
                        CollectionFilter.opened,
                    onTap: () =>
                        widget.controller.setFilter(CollectionFilter.opened),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'Not opened',
                    selected:
                        widget.controller.filter.value ==
                        CollectionFilter.notOpened,
                    onTap: () =>
                        widget.controller.setFilter(CollectionFilter.notOpened),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'Rare Find',
                    selected:
                        widget.controller.filter.value ==
                        CollectionFilter.rareFind,
                    onTap: () =>
                        widget.controller.setFilter(CollectionFilter.rareFind),
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

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.controller, required this.onClose});

  final CollectionController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 156,
        height: 148,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          color: AppColors.menuSurface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowBlack32,
              blurRadius: 4.8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(7, 12, 6, 10),
        child: Obx(
          () => Column(
            children: [
              _SortMenuRow(
                label: 'Name',
                selected: controller.sort.value == CollectionSort.name,
                ascending: controller.sortAscending.value,
                onTap: () {
                  controller.toggleSort(CollectionSort.name);
                  onClose();
                },
              ),
              const SizedBox(height: 5),
              _SortMenuRow(
                label: 'Price',
                selected: controller.sort.value == CollectionSort.price,
                ascending: controller.sortAscending.value,
                onTap: () {
                  controller.toggleSort(CollectionSort.price);
                  onClose();
                },
              ),
              const SizedBox(height: 5),
              _SortMenuRow(
                label: 'Fill Rate',
                selected: controller.sort.value == CollectionSort.fillRate,
                ascending: controller.sortAscending.value,
                onTap: () {
                  controller.toggleSort(CollectionSort.fillRate);
                  onClose();
                },
              ),
              _SortMenuRow(
                label: 'Added Time',
                selected: controller.sort.value == CollectionSort.addedTime,
                ascending: controller.sortAscending.value,
                onTap: () {
                  controller.toggleSort(CollectionSort.addedTime);
                  onClose();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortMenuRow extends StatelessWidget {
  const _SortMenuRow({
    required this.label,
    required this.selected,
    required this.ascending,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool ascending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.menuRowSelected : Colors.transparent;
    final upColor = selected && ascending
        ? AppColors.white
        : AppColors.sortChevronInactive;
    final downColor = selected && !ascending
        ? AppColors.white
        : AppColors.sortChevronInactive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 29,
        width: 143,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body16().copyWith(
                  fontSize: 12,
                  fontFamily: 'Inter',
                  color: AppColors.white,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  AppAssets.sortChevronUp,
                  width: 6,
                  height: 7,
                  colorFilter: ColorFilter.mode(upColor, BlendMode.srcIn),
                ),
                const SizedBox(height: 2),
                Transform.rotate(
                  angle: 3.1415926535,
                  child: SvgPicture.asset(
                    AppAssets.sortChevronDown,
                    width: 6,
                    height: 7,
                    colorFilter: ColorFilter.mode(downColor, BlendMode.srcIn),
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
    final urls = item.resolvedImageCandidates;
    final ratio = item.fillRatio;
    Widget bottlePlaceholder() => Image.asset(
      AppAssets.collectionBottlePlaceholder,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );

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
                            if (urls.isNotEmpty)
                              _NetworkImageWithFallback(
                                urls: urls,
                                fit: BoxFit.contain,
                                placeholder: bottlePlaceholder(),
                                cacheWidthPx:
                                    (imageSide *
                                            MediaQuery.devicePixelRatioOf(
                                              context,
                                            ))
                                        .round(),
                              ),
                            if (urls.isEmpty) bottlePlaceholder(),
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

class _NetworkImageWithFallback extends StatefulWidget {
  const _NetworkImageWithFallback({
    required this.urls,
    required this.fit,
    required this.placeholder,
    required this.cacheWidthPx,
  });

  final List<String> urls;
  final BoxFit fit;
  final Widget placeholder;
  final int cacheWidthPx;

  @override
  State<_NetworkImageWithFallback> createState() =>
      _NetworkImageWithFallbackState();
}

class _NetworkImageWithFallbackState extends State<_NetworkImageWithFallback> {
  int _index = 0;
  bool _scheduled = false;
  bool _loaded = false;
  bool _loadScheduled = false;

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
  }

  void _scheduleNext() {
    if (_scheduled) return;
    if (_index >= widget.urls.length - 1) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _index += 1;
        _scheduled = false;
        _loaded = false;
      });
    });
  }

  void _markLoaded() {
    if (_loaded || _loadScheduled) return;
    _loadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _loaded = true;
        _loadScheduled = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.urls[_index];
    _log('[CollectionImage] try ${_index + 1}/${widget.urls.length}: $url');

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedOpacity(
          opacity: _loaded ? 0 : 1,
          duration: const Duration(milliseconds: 140),
          child: widget.placeholder,
        ),
        CachedNetworkImage(
          imageUrl: url,
          cacheManager: AppCacheManager.images,
          imageBuilder: (context, provider) {
            _markLoaded();
            return Image(
              image: provider,
              fit: widget.fit,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
            );
          },
          memCacheWidth: widget.cacheWidthPx > 0 ? widget.cacheWidthPx : null,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholderFadeInDuration: Duration.zero,
          placeholder: (context, _) => const SizedBox.shrink(),
          errorWidget: (context, error, stackTrace) {
            _log('[CollectionImage] fail: $url');
            _log('[CollectionImage] error: $error');
            _scheduleNext();
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
