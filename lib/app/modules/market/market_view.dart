import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../category_detail/category_detail_controller.dart';
import '../category_detail/category_detail_view.dart';
import '../../data/repositories/categories_repository.dart';
import 'market_controller.dart';

class MarketView extends GetView<MarketController> {
  const MarketView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.surfaceDeep, AppColors.surfaceDeep]),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.overlayBlack20)),
          SafeArea(
            top: false,
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold1),
                );
              }

              return RefreshIndicator(
                color: AppColors.gold1,
                onRefresh: controller.forceReload,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240) {
                      controller.loadMore();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 108, 16, 24),
                    itemCount: controller.categories.length + 1,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == controller.categories.length) {
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

                      final c = controller.categories[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Get.to(
                              () => const CategoryDetailView(),
                              binding: BindingsBuilder(() {
                                Get.lazyPut<CategoryDetailController>(
                                  () => CategoryDetailController(
                                    repo: Get.find<CategoriesRepository>(),
                                    categoryId: c.id,
                                    initialName: c.name,
                                  ),
                                );
                              }),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: AppColors.cardSurfaceGradient,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body16().copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${c.totalBottles}',
                                  style: AppTextStyles.body16().copyWith(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Bottles',
                                  style: AppTextStyles.body16().copyWith(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
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

