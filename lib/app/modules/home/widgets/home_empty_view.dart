import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/animations/staggered_entrance.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/platform/app_platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/common_primary_button.dart';
import '../../../routes/app_routes.dart';
import '../home_controller.dart';

/// Home before the first bottle: a gently floating bottle over a breathing
/// gold glow, and one call to action.
class HomeEmptyView extends StatelessWidget {
  const HomeEmptyView({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceDeep,
      child: SafeArea(
        top: false,
        child: RefreshIndicator.adaptive(
          onRefresh: controller.forceReload,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: AppPlatform.scrollPhysics,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      kShellTabBodyContentTopGap + 8,
                      24,
                      24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FadeSlideEntrance(child: _FloatingBottle()),
                        const SizedBox(height: 16),
                        FadeSlideEntrance(
                          index: 2,
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AppColors.gold2, AppColors.gold1],
                              stops: [0.21591, 0.90909],
                            ).createShader(bounds),
                            blendMode: BlendMode.srcIn,
                            child: Text(
                              'Your collection\nis empty.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headingL().copyWith(
                                fontSize: 32,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeSlideEntrance(
                          index: 3,
                          child: SizedBox(
                            width: 300,
                            child: Text(
                              'Add your first bottle and be a part of this '
                              'wonderful journey.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyL().copyWith(
                                fontSize: 15,
                                color: AppColors.textCream,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeSlideEntrance(
                          index: 4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: CommonPrimaryButton(
                              label: 'Add Your First Bottle',
                              onPressed: () async {
                                final res = await Get.toNamed(
                                  AppRoutes.tasteBottles,
                                  arguments: {'autoCloseOnAdded': true},
                                );
                                if (res == true) {
                                  await controller.forceReload();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FloatingBottle extends StatefulWidget {
  const _FloatingBottle();

  @override
  State<_FloatingBottle> createState() => _FloatingBottleState();
}

class _FloatingBottleState extends State<_FloatingBottle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: AppMotion.ambient * 1.5,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final wave = math.sin(_loop.value * 2 * math.pi);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 190 + wave * 10,
              height: 190 + wave * 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold1.withValues(alpha: 0.16 + wave * 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Transform.translate(offset: Offset(0, wave * -6), child: child),
          ],
        );
      },
      child: SizedBox(
        height: 200,
        width: 200,
        child: Image.asset(AppAssets.homeBottle, fit: BoxFit.contain),
      ),
    );
  }
}
