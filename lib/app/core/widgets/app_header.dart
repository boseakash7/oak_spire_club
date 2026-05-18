import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../modules/session/user_session_controller.dart';

/// Toolbar row height for [AppHeader] / shell [PreferredSize].
const double kShellAppBarHeight = kToolbarHeight;

/// Gap between the bottom of the shell app bar and the first line of tab
/// content. The scaffold lays out the body **below** the app bar
/// (`extendBodyBehindAppBar: false`), so this is only a small design inset.
const double kShellTabBodyContentTopGap = 12;

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title = AppConstants.appName,
  });

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kShellAppBarHeight);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<UserSessionController>()) {
      Get.put<UserSessionController>(UserSessionController(), permanent: true);
    }
    final session = Get.find<UserSessionController>();
    return AppBar(
      backgroundColor: AppColors.surfaceDeep,
      surfaceTintColor: AppColors.surfaceDeep,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 23),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 5,
              fit: FlexFit.loose,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.goldGradient.createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: AppTextStyles.heading32Bold().copyWith(
                      fontSize: 18,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 4,
              child: Obx(
                () => Text(
                  'Good morning, ${session.displayName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                    color: const Color(0xFFF5F5F5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

