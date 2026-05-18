import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/network/app_cache_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/price_formatter.dart';
import '../../core/widgets/app_header.dart';
import '../../data/models/category_bottle_model.dart';
import '../home/home_controller.dart';
import '../navigation/bottom_nav_controller.dart';
import '../../routes/app_routes.dart';
import 'taste_controller.dart';
import 'taste_loading_view.dart';

class TasteView extends GetView<TasteController> {
  const TasteView({super.key});

  Future<void> _handleAddedSuccess() async {
    final nav = Get.isRegistered<BottomNavController>()
        ? Get.find<BottomNavController>()
        : null;
    nav?.setIndex(0);

    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().forceReload();
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
      appBar: const AppHeader(),
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

                return RefreshIndicator(
                  color: AppColors.gold1,
                  onRefresh: controller.forceReload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(23, 104, 23, 24),
                    children: [
                      _SearchInput(controller: controller.searchCtrl),
                      const SizedBox(height: 16),
                      _CategoryRow(controller: controller),
                      const SizedBox(height: 16),
                      ...controller.visibleBottles.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _BottleRow(
                            bottle: b,
                            onAdd: () => _openAddCollection(
                              arguments: {
                                'prefill': {
                                  'id': b.id,
                                  'name': b.bottleName,
                                  'image': b.image,
                                  'average': b.average,
                                  'quantity': 1,
                                  'fill': 100,
                                },
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _AddOwnBottleRow(onTap: () => _openAddCollection()),
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
  const _SearchInput({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: TextField(
        controller: controller,
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
      height: 27,
      child: Obx(
        () => ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: controller.categories.length + 1,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final isAll = index == 0;
            final label = isAll ? 'All' : controller.categories[index - 1].name;
            final id = isAll ? '' : controller.categories[index - 1].id;
            final selected = controller.selectedCategoryId.value == id;
            return InkWell(
              borderRadius: BorderRadius.circular(42),
              onTap: () => controller.selectCategory(id),
              child: Container(
                height: 27,
                constraints: const BoxConstraints(minWidth: 78),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(42),
                  gradient: selected
                      ? const LinearGradient(
                          colors: [
                            AppColors.goldBright,
                            AppColors.goldRich,
                            AppColors.goldBright,
                          ],
                        )
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF271C16), Color(0xFF201512)],
                        ),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 14,
                    color: selected ? AppColors.white : AppColors.textCream,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BottleRow extends StatelessWidget {
  const _BottleRow({required this.bottle, required this.onAdd});
  final CategoryBottleModel bottle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final imageUrl = bottle.resolvedImageUrl;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.black,
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
                          fit: BoxFit.cover,
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
                    'Proof 45',
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
          color: AppColors.black,
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
