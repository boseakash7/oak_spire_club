import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/app_cache_manager.dart';
import '../../core/widgets/animated_list_entrance.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/category_bottle_model.dart';
import 'category_detail_controller.dart';

class CategoryDetailView extends GetView<CategoryDetailController> {
  const CategoryDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDeep,
      appBar: AppScreenAppBar(
        title: Obx(() {
          final name = controller.detail.value?.category.name ??
              controller.initialName ??
              'Category';
          return Text(
            name,
            style: AppTextStyles.body16().copyWith(fontWeight: FontWeight.w700),
          );
        }),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient:
              LinearGradient(colors: [AppColors.surfaceDeep, AppColors.surfaceDeep]),
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

                final d = controller.detail.value;
                if (d == null) {
                  return Center(
                    child: Text(
                      'Unable to load category.',
                      style: AppTextStyles.body16().copyWith(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.gold1,
                  onRefresh: controller.load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                        sliver: SliverToBoxAdapter(
                          child: _HeaderCard(
                            title: d.category.name,
                            totalBottles: d.category.totalBottles,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList.separated(
                          itemCount: d.bottles.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final b = d.bottles[index];
                            return AnimatedListEntrance(
                              index: index,
                              child: _BottleRow(bottle: b),
                            );
                          },
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.title, required this.totalBottles});

  final String title;
  final int totalBottles;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: AppColors.cardSurfaceGradient,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body16().copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: AppColors.black.withValues(alpha: 0.25),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Text(
              '$totalBottles bottles',
              style: AppTextStyles.body16().copyWith(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottleRow extends StatelessWidget {
  const _BottleRow({required this.bottle});

  final CategoryBottleModel bottle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: AppColors.cardSurfaceGradient,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _BottleThumb(imageUrl: bottle.resolvedImageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bottle.bottleName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(label: 'Avg', value: bottle.average),
                    _Chip(label: 'Low', value: bottle.low),
                    _Chip(label: 'High', value: bottle.high),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottleThumb extends StatelessWidget {
  const _BottleThumb({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const double size = 58;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.black.withValues(alpha: 0.22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.local_bar, color: AppColors.textMuted, size: 20),
    );

    final url = imageUrl;
    if (url == null || url.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: CachedNetworkImage(
        imageUrl: url,
        cacheManager: AppCacheManager.images,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 120),
        placeholder: (context, _) => placeholder,
        errorWidget: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final v = value?.toString().trim();
    final show = v != null && v.isNotEmpty && v != 'null';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.black.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        show ? '$label \$$v' : '$label —',
        style: AppTextStyles.body16().copyWith(
          fontSize: 11,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

