import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/app_cache_manager.dart';
import '../../core/storage/app_storage.dart';
import '../../core/widgets/animated_list_entrance.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/price_formatter.dart';
import '../../core/utils/proof_formatter.dart';
import '../../core/widgets/app_header.dart';
import '../../data/models/bluebook_model.dart';
import '../../routes/app_routes.dart';
import 'market_controller.dart';
import 'market_loading_view.dart';

class MarketView extends GetView<MarketController> {
  const MarketView({super.key});

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
            child: Obx(() {
              if (controller.isLoading.value) {
                return const MarketLoadingView();
              }

              return RefreshIndicator(
                color: AppColors.gold1,
                onRefresh: () async {
                  if (Get.isRegistered<AppAnalyticsController>()) {
                    unawaited(
                      AppAnalyticsController.to.logTap('market_pull_refresh'),
                    );
                  }
                  await controller.forceReload();
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240) {
                      controller.loadMore();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      23,
                      kShellTabBodyContentTopGap,
                      23,
                      24,
                    ),
                    itemCount: controller.visibleBottles.length + 2,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _Header(controller: controller);
                      }

                      if (index == controller.visibleBottles.length + 1) {
                        return Obx(() {
                          if (!controller.isLoadingMore.value) {
                            return const SizedBox(height: 8);
                          }
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.gold1,
                                ),
                              ),
                            ),
                          );
                        });
                      }

                      final b = controller.visibleBottles[index - 1];
                      return AnimatedListEntrance(
                        index: index - 1,
                        child: _BenchmarkCard(bottle: b),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});
  final MarketController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: controller.onSearchChanged,
          style: AppTextStyles.body16().copyWith(
            fontSize: 16,
            color: AppColors.white,
          ),
          decoration: InputDecoration(
            hintText: 'Search from 10000+ bottoles',
            hintStyle: AppTextStyles.body16().copyWith(
              fontSize: 16,
              color: AppColors.white,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.white,
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: AppColors.panel,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.inputBorderFocused),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _CategoryRow(controller: controller),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.controller});
  final MarketController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Obx(
        () => ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.only(right: 4),
          itemCount: controller.categories.length + 1,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final isAll = index == 0;
            final label = isAll ? 'All' : controller.categories[index - 1].name;
            final id = isAll ? '' : controller.categories[index - 1].id;
            final selected = controller.selectedCategoryId.value == id;
            return AppFilterChip(
              label: label,
              selected: selected,
              onTap: () {
                if (Get.isRegistered<AppAnalyticsController>()) {
                  unawaited(
                    AppAnalyticsController.to.logTap(
                      'market_category_select',
                      {'category_id': id},
                    ),
                  );
                }
                controller.selectCategory(id);
              },
            );
          },
        ),
      ),
    );
  }
}

class _BenchmarkCard extends StatelessWidget {
  const _BenchmarkCard({required this.bottle});
  final BluebookModel bottle;

  @override
  Widget build(BuildContext context) {
    final price = PriceFormatter.format(bottle.average);
    final low = PriceFormatter.format(bottle.low);
    final high = PriceFormatter.format(bottle.high);
    final imageUrl = _resolveImageUrl(bottle.image);
    final proofLabel = ProofFormatter.formatLabelOrFallback(bottle.proof);
    final ratingLabel = bottle.rating ?? '—';
    final movementLabel =
        PriceFormatter.formatPriceMovementLabel(bottle.priceMovement);
    final movementColor =
        PriceFormatter.priceMovementColor(bottle.priceMovement);
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () {
        if (Get.isRegistered<AppAnalyticsController>()) {
          unawaited(
            AppAnalyticsController.to.logTap(
              'market_benchmark_open',
              {'bottle_id': bottle.id},
            ),
          );
        }
        Get.toNamed(
          AppRoutes.benchmarkDetail,
          arguments: {
            'id': bottle.id,
            'name': bottle.bottleName,
            'image': bottle.image,
            'average': bottle.average,
            'low': bottle.low,
            'high': bottle.high,
            'proof': bottle.proof,
            'description': bottle.description,
            'rating': bottle.rating,
            'price_movement': bottle.priceMovement,
          },
        );
      },
      child: Container(
        height: 97.247,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          gradient: AppColors.cardSurfaceGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              left: 6.16,
              top: 13.8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 62.62,
                  height: 62.62,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.bottleRadialGlow,
                        ),
                      ),
                      if (imageUrl != null)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          cacheManager: AppCacheManager.images,
                          fit: BoxFit.contain,
                          placeholder: (context, _) => _placeholder(),
                          errorWidget: (context, error, stackTrace) =>
                              _placeholder(),
                        )
                      else
                        _placeholder(),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 72,
              top: 14,
              right: 58,
              child: Text(
                bottle.bottleName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body16().copyWith(
                  fontSize: 15,
                  color: AppColors.white,
                ),
              ),
            ),
            Positioned(
              left: 72,
              bottom: 14,
              child: Row(
                children: [
                  Text(
                    proofLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body16().copyWith(
                      fontSize: 10,
                      color: AppColors.textWolf,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SvgPicture.asset(
                    AppAssets.star,
                    width: 8,
                    height: 8,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textWolf,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    ratingLabel,
                    style: AppTextStyles.body16().copyWith(
                      fontSize: 10,
                      color: AppColors.textWolf,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              top: 48,
              width: 132,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body16().copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textCream,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SvgPicture.asset(
                        AppAssets.marketTrend,
                        width: 10,
                        height: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        movementLabel,
                        style: AppTextStyles.body16().copyWith(
                          fontSize: 12,
                          color: movementColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '$low - $high',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.body16().copyWith(
                            fontSize: 10,
                            color: AppColors.textWolf,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              top: 14,
              child: const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.iconNeutralLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Image.asset(
      AppAssets.collectionBottlePlaceholder,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
  }

  String? _resolveImageUrl(String? raw0) {
    final raw = raw0?.trim();
    if (raw == null || raw.isEmpty || raw == 'null') return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    final uploadUrl = AppStorage.uploadUrl;
    if (uploadUrl != null && uploadUrl.trim().isNotEmpty) {
      return '${uploadUrl.trim().replaceAll(RegExp(r'/+$'), '')}/$raw';
    }

    final api = Uri.parse(AppConstants.apiBaseUrl);
    return Uri(
      scheme: api.scheme,
      host: api.host,
      port: api.hasPort ? api.port : null,
      path: raw.startsWith('/') ? raw : '/$raw',
    ).toString();
  }
}
