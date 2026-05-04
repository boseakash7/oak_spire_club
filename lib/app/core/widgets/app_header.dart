import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../modules/session/user_session_controller.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title = 'Bourbonuer',
  });

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<UserSessionController>()) {
      Get.put<UserSessionController>(UserSessionController(), permanent: true);
    }
    final session = Get.find<UserSessionController>();
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
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
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.goldGradient.createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading32Bold().copyWith(
                    fontSize: 24,
                    height: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Obx(
                () => Text(
                  'Good morning, ${session.displayName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.body16().copyWith(
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

