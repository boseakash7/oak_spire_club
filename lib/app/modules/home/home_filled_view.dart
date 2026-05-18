import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/price_formatter.dart';
import '../../core/widgets/app_header.dart';
import '../../data/models/collection_item_display.dart';
import 'home_controller.dart';
import 'widgets/home_value_chart.dart';

/// Space between section heading and horizontal cards (Top moved / Quick Stats).
const double _kHomeHeadingToCardsGap = 20;

class HomeFilledView extends StatelessWidget {
  const HomeFilledView({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF080405), Color(0xFF080405)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                23,
                kShellTabBodyContentTopGap,
                0,
                96,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 23),
                    child: _CollectionValue(home: home),
                  ),
                  const SizedBox(height: 38),
                  Padding(
                    padding: const EdgeInsets.only(right: 23),
                    child: _SectionHeader(
                      title: 'Top moved bottles',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(height: _kHomeHeadingToCardsGap),
                  Obx(() {
                    final bottles = home.topMovedBottles;
                    if (bottles.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return SizedBox(
                      height: 68,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.only(left: 0, right: 23),
                        itemCount: bottles.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final item = bottles[index];
                          final subtitle = item.lineSubtitle.trim().isNotEmpty
                              ? item.lineSubtitle.trim()
                              : item.proofLabel;
                          final movementRaw = item.priceMovementRaw;
                          return _TrendingCard(
                            title: item.lineTitle,
                            subtitle: subtitle,
                            price: item.marketAverageLabel,
                            changeText: PriceFormatter.formatPriceMovementLabel(
                              movementRaw,
                            ),
                            changeColor: PriceFormatter.priceMovementColor(
                              movementRaw,
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.only(right: 23),
                    child: _SectionHeader(title: 'Quick Stats', onTap: () {}),
                  ),
                  const SizedBox(height: _kHomeHeadingToCardsGap),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      padding: const EdgeInsets.only(left: 0, right: 8),
                      itemCount: 4,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        if (index == 2) {
                          return const _StatCardRating(
                            label: 'Collection\nRating',
                            value: '4.5',
                          );
                        }
                        final label = switch (index) {
                          0 => 'Total\nCollection',
                          1 => 'Total\nDrunk',
                          _ => 'Total\nCollection',
                        };
                        if (index == 0 || index == 3) {
                          return Obx(
                            () => _StatCard(
                              label: label,
                              value: home.totalCollectionCount.value.toString(),
                            ),
                          );
                        }
                        const value = '12';
                        return _StatCard(label: label, value: value);
                      },
                    ),
                  ),
                  const SizedBox(height: 34),
                  Padding(
                    padding: const EdgeInsets.only(right: 23),
                    child: const HomeValueChart(),
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

class _CollectionValue extends StatelessWidget {
  const _CollectionValue({required this.home});

  final HomeController home;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Collection Value',
          style: AppTextStyles.body16().copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFF1E8BE),
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gold2, AppColors.gold1],
            stops: [0.21591, 0.90909],
          ).createShader(bounds),
          child: Obx(
            () => Text(
              home.collectionValueText.value,
              style: AppTextStyles.button20Bold().copyWith(
                fontSize: 36,
                height: 1.12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Text(
            home.movedText.value,
            style: AppTextStyles.body16().copyWith(
              color: const Color(0xFF9D9C9C),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.body16().copyWith(color: AppColors.white),
        ),
        const Spacer(),
        InkResponse(
          onTap: onTap,
          radius: 20,
          child: SvgPicture.asset(
            AppAssets.iconArrowRight,
            height: 13,
            width: 6,
            colorFilter: const ColorFilter.mode(
              AppColors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.changeText,
    required this.changeColor,
  });

  final String title;
  final String subtitle;
  final String price;
  final String changeText;
  final Color changeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 262,
      height: 68,
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A342E)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF271C16), Color(0xFF201512)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body16().copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 14,
                    color: const Color(0xFF87665A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                changeText,
                style: AppTextStyles.body16().copyWith(
                  fontSize: 15,
                  color: changeColor,
                ),
              ),
              const Spacer(),
              Text(
                price,
                style: AppTextStyles.body16().copyWith(
                  fontSize: 15,
                  color: const Color(0xFFF1E8BE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A342E)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF271C16), Color(0xFF201512)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.body16().copyWith(
              fontSize: 13,
              color: const Color(0xFF997C71),
              height: 1.05,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.body16().copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF1E8BE),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardRating extends StatelessWidget {
  const _StatCardRating({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A342E)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF271C16), Color(0xFF201512)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.body16().copyWith(
              fontSize: 13,
              color: const Color(0xFF997C71),
              height: 1.05,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF1E8BE),
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.star_rounded,
                  size: 22,
                  color: const Color(0xFFF1E8BE),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
