import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/common_primary_button.dart';
import '../../routes/app_routes.dart';
import 'home_controller.dart';
import 'home_filled_view.dart';
import 'home_loading_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const HomeLoadingView();
      }
      if (controller.hasCollection.value) {
        return const HomeFilledView();
      }

      return _HomeEmptyView(
        key: key,
        controller: controller,
      );
    });
  }
}

class _HomeEmptyView extends StatelessWidget {
  const _HomeEmptyView({
    super.key,
    required this.controller,
  });

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
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
            child: RefreshIndicator(
              color: AppColors.gold1,
              onRefresh: controller.forceReload,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
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
                              const Spacer(),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          AppColors.gold1.withValues(alpha: 0.18),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 200,
                                    width: 200,
                                    child: Image.asset(
                                      AppAssets.homeBottle,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ShaderMask(
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
                                  style: AppTextStyles.button20Bold().copyWith(
                                    fontSize: 32,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: 300,
                                child: Text(
                                  'Add your first bottle and be a part of this wonderful journey.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body16().copyWith(
                                    fontSize: 15,
                                    color: const Color(0xFFF1E8BE),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Padding(
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
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
