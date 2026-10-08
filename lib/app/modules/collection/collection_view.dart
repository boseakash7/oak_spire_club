import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../core/animations/app_motion.dart';
import '../../core/animations/state_switcher.dart';
import '../../core/animations/staggered_entrance.dart';
import '../../core/constants/app_assets.dart';
import '../../core/platform/app_platform.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_pressable.dart';
import '../../routes/app_routes.dart';
import 'collection_controller.dart';
import 'collection_loading_view.dart';
import 'widgets/collection_insights.dart';

const double _kInset = 23;

/// The Collection tab: quick stats, the collection's value, the portfolio
/// mix, the value chart, the top priced bottles and "View all bottles",
/// which opens the full list ([CollectionBottlesView]). See
/// [CollectionInsights].
class CollectionView extends GetView<CollectionController> {
  const CollectionView({super.key});

  @override
  Widget build(BuildContext context) {
    _precachePlaceholder(context);
    return Obx(() {
      final loading = controller.isLoading.value;
      return AppStateSwitcher(
        stateKey: loading,
        child: loading
            ? const CollectionLoadingView()
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  _CollectionBody(controller: controller),
                  Positioned(
                    right: 16,
                    bottom: 24 + MediaQuery.paddingOf(context).bottom,
                    child: _AddBottleFab(controller: controller),
                  ),
                ],
              ),
      );
    });
  }

  static bool _precached = false;

  static void _precachePlaceholder(BuildContext context) {
    if (_precached) return;
    _precached = true;
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

  Future<void> _refresh() async {
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(AppAnalyticsController.to.logTap('collection_pull_refresh'));
    }
    await controller.forceReload();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceDeep,
      child: SafeArea(
        top: false,
        child: RefreshIndicator.adaptive(
          onRefresh: _refresh,
          child: StaggerScope(
            child: CustomScrollView(
              physics: AppPlatform.scrollPhysics,
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(height: kShellTabBodyContentTopGap),
                ),
                Obx(() {
                  if (controller.items.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          _kInset,
                          8,
                          _kInset,
                          120,
                        ),
                        child: Center(
                          child: _EmptyState(controller: controller),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    // Room for the add button over the end of the page.
                    padding: const EdgeInsets.only(bottom: 120),
                    sliver: SliverToBoxAdapter(
                      child: CollectionInsights(
                        controller: controller,
                        inset: _kInset,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.controller});

  final CollectionController controller;

  @override
  Widget build(BuildContext context) {
    // An empty collection is the moment a user is most likely to bounce, so
    // send them straight to the bottle browser.
    return AppEmptyState(
      icon: Icons.liquor_rounded,
      title: 'Your collection is empty',
      message:
          'Add your first bottle and Oak Spire will track what it is worth '
          'against the BSMI benchmark.',
      actionLabel: 'Browse bottles',
      onAction: () async {
        final res = await Get.toNamed(AppRoutes.tasteBottles);
        if (res == true) await controller.forceReload();
      },
    );
  }
}

/// Gold "+" button: pops in when the tab appears and spins a quarter turn
/// on press.
class _AddBottleFab extends StatefulWidget {
  const _AddBottleFab({required this.controller});

  final CollectionController controller;

  @override
  State<_AddBottleFab> createState() => _AddBottleFabState();
}

class _AddBottleFabState extends State<_AddBottleFab> {
  static const double _size = 60;
  double _turns = 0;

  Future<void> _onTap() async {
    setState(() => _turns += 0.25);
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(AppAnalyticsController.to.logTap('collection_add_bottle_fab'));
    }
    final res = await Get.toNamed(AppRoutes.tasteBottles);
    if (res == true) await widget.controller.forceReload();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, AppMotion.slow),
      curve: AppMotion.emphasized,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: AppPressable(
        onTap: _onTap,
        haptic: PressHaptic.tap,
        scale: 0.9,
        semanticLabel: 'Add a bottle',
        child: Container(
          width: _size,
          height: _size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.goldGradient,
            boxShadow: AppShadows.fab,
          ),
          child: AnimatedRotation(
            turns: _turns,
            duration: AppMotion.of(context, AppMotion.medium),
            curve: AppMotion.emphasized,
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.black,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
