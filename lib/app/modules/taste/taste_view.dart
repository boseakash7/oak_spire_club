import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/network/app_cache_manager.dart';
import '../../core/widgets/animated_list_entrance.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/price_formatter.dart';
import '../../core/utils/proof_formatter.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../../core/widgets/app_header.dart';
import '../../data/models/bluebook_model.dart';
import '../collection/collection_controller.dart';
import '../market/benchmark_detail_controller.dart';
import '../home/home_controller.dart';
import '../navigation/bottom_nav_controller.dart';
import '../../routes/app_routes.dart';
import 'taste_controller.dart';
import 'taste_loading_view.dart';

class TasteView extends GetView<TasteController> {
  const TasteView({super.key});

  Future<void> _handleAddedSuccess() async {
    if (Get.isRegistered<BottomNavController>()) {
      Get.find<BottomNavController>().setIndex(1);
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

  Future<void> _openAddCollection({Map<String, dynamic>? arguments}) async {
    final res = await Get.toNamed(
      AppRoutes.addToCollection,
      arguments: arguments,
    );
    if (res == true) {
      await _handleAddedSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppHeader(showTitle: false),
      body: Container(
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
                  return const TasteLoadingView();
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(23, 104, 23, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SearchInput(
                        controller: controller.searchCtrl,
                        onChanged: controller.onSearchChanged,
                      ),
                      const SizedBox(height: 16),
                      _CategoryRow(controller: controller),
                      const SizedBox(height: 16),
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.gold1,
                          onRefresh: controller.forceReload,
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (n) {
                              if (n.metrics.pixels >=
                                  n.metrics.maxScrollExtent - 240) {
                                controller.loadMore();
                              }
                              return false;
                            },
                            child: Obx(
                              () => ListView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 24),
                                children: [
                                  ...controller.visibleBottles
                                      .asMap()
                                      .entries
                                      .map(
                                    (e) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 6),
                                      child: AnimatedListEntrance(
                                        index: e.key,
                                        child: _BottleRow(
                                          bottle: e.value,
                                          onAdd: () async {
                                            final res = await controller
                                                .addBottleToCollection(
                                              e.value,
                                            );
                                            if (res == true) {
                                              await _handleAddedSuccess();
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (controller.isLoadingMore.value)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14),
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
                                    )
                                  else
                                    const SizedBox(height: 6),
                                  _AddOwnBottleRow(
                                    onTap: () => _openAddCollection(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.body16().copyWith(
          fontSize: 16,
          color: AppColors.white,
        ),
        decoration: InputDecoration(
          hintText: 'Search bottles here',
          hintStyle: AppTextStyles.body16().copyWith(
            fontSize: 16,
            color: AppColors.white,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.white),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 0,
          ),
          filled: true,
          fillColor: const Color(0xFF10090B),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFF414141)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFF585858)),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.controller});
  final TasteController controller;

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
              onTap: () => controller.selectCategory(id),
            );
          },
        ),
      ),
    );
  }
}

class _BottleRow extends StatelessWidget {
  const _BottleRow({required this.bottle, required this.onAdd});
  final BluebookModel bottle;
  final VoidCallback onAdd;

  String? get _imageUrl => resolveBenchmarkDetailImageUrl(bottle.image);

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF3C3B3B))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              width: 62,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl == null
                      ? _placeholder()
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          cacheManager: AppCacheManager.images,
                          width: 56,
                          height: 56,
                          // Match Benchmark list behavior: show full bottle (no crop).
                          fit: BoxFit.contain,
                          placeholder: (context, _) => _placeholder(),
                          errorWidget: (context, error, stackTrace) =>
                              _placeholder(),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bottle.bottleName,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body16().copyWith(
                      fontSize: 14,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ProofFormatter.formatLabelOrFallback(bottle.proof),
                    style: AppTextStyles.body16().copyWith(
                      fontSize: 10,
                      color: const Color(0xFF89746D),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 58,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 10),
                InkResponse(
                  onTap: onAdd,
                  radius: 16,
                  child: const Icon(
                    Icons.add,
                    color: AppColors.goldBright,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  PriceFormatter.format(bottle.average),
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textCream,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: const Color(0x33000000),
      borderRadius: BorderRadius.circular(8),
    ),
    alignment: Alignment.center,
    child: Image.asset(
      AppAssets.collectionBottlePlaceholder,
      width: 56,
      height: 56,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    ),
  );
}

class _AddOwnBottleRow extends StatelessWidget {
  const _AddOwnBottleRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF3C3B3B))),
        ),
        child: Row(
          children: [
            const SizedBox(width: 17),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.goldBright,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.white),
            ),
            const SizedBox(width: 18),
            Text(
              'Add your own bottles',
              style: AppTextStyles.body16().copyWith(
                fontSize: 16,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
