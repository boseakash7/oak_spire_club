import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/animations/staggered_entrance.dart';
import '../../core/platform/app_platform.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_header.dart';
import 'home_controller.dart';
import 'widgets/home_chart_footer.dart';
import 'widgets/home_quick_stats.dart';
import 'widgets/home_top_moved.dart';
import 'widgets/home_value_chart.dart';
import 'widgets/home_value_header.dart';

/// Left inset shared by every section; the horizontal strips scroll past the
/// right edge instead.
const double _kInset = 23;

/// Home with a collection: value, top movers, quick stats, and the value vs
/// BSMI chart. Sections rise in one after another on first show.
class HomeFilledView extends StatelessWidget {
  const HomeFilledView({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();

    return ColoredBox(
      color: AppColors.surfaceDeep,
      child: SafeArea(
        top: false,
        child: RefreshIndicator.adaptive(
          onRefresh: home.forceReload,
          child: SingleChildScrollView(
            physics: AppPlatform.scrollPhysics,
            padding: const EdgeInsets.fromLTRB(
              _kInset,
              kShellTabBodyContentTopGap,
              0,
              96,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideEntrance(
                  child: Padding(
                    padding: const EdgeInsets.only(right: _kInset),
                    child: HomeValueHeader(home: home),
                  ),
                ),
                const SizedBox(height: 34),
                FadeSlideEntrance(
                  index: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(title: 'Top moved bottles'),
                      const SizedBox(height: 12),
                      HomeTopMoved(home: home, trailingInset: _kInset),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FadeSlideEntrance(
                  index: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(title: 'Quick Stats'),
                      const SizedBox(height: 12),
                      HomeQuickStats(home: home),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FadeSlideEntrance(
                  index: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full-bleed chart (~2px from the screen edges).
                      LayoutBuilder(
                        builder: (context, _) {
                          const bleed = _kInset - kHomeChartHorizontalInset;
                          final w =
                              MediaQuery.sizeOf(context).width -
                              kHomeChartHorizontalInset * 2;
                          return Transform.translate(
                            offset: const Offset(-bleed, 0),
                            child: SizedBox(
                              width: w,
                              child: const HomeValueChart(),
                            ),
                          );
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: _kInset),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 14),
                            HomeChartLegend(),
                            HomeChartFooter(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.bodyL());
  }
}
