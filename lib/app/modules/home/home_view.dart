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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  0,
                  kShellTabBodyContentTopGap,
                  0,
                  66,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 270,
                      width: 270,
                      child: Image.asset(
                        AppAssets.homeBottle,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 18),
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
                          fontSize: 36,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 312,
                      child: Text(
                        'Add your first bottle and be a part of this wonderfull journey.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body16().copyWith(
                          color: const Color(0xFFF1E8BE),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 58),
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
