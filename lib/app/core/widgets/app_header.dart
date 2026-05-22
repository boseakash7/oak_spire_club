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
    this.showTitle = true,
  });

  final String title;
  final bool showTitle;

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
      toolbarHeight: kShellAppBarHeight,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 23),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showTitle) ...[
              Flexible(
                flex: 5,
                fit: FlexFit.loose,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _TitleText(title: title),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ] else
              const Spacer(),
            if (showTitle)
              Flexible(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _GreetingText(session: session),
                ),
              )
            else
              _GreetingText(session: session),
          ],
        ),
      ),
    );
  }
}

class _GreetingText extends StatelessWidget {
  const _GreetingText({required this.session});

  final UserSessionController session;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Text(
        session.greetingText,
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
    );
  }
}

class _TitleText extends StatelessWidget {
  const _TitleText({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => AppColors.goldGradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        title,
        maxLines: 1,
        style: AppTextStyles.heading32Bold().copyWith(
          fontSize: 18,
          height: 1.0,
        ),
      ),
    );
  }
}
