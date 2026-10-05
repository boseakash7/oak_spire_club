import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../animations/app_motion.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../modules/home/home_controller.dart';
import '../../modules/session/user_session_controller.dart';
import 'bottle_meta_chip.dart';

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
                    // Tab changes swap the title with a short fade-rise.
                    child: AnimatedSwitcher(
                      duration: AppMotion.of(context, AppMotion.medium),
                      switchInCurve: AppMotion.emphasizedDecelerate,
                      switchOutCurve: AppMotion.exit,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, ?current],
                      ),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.35),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _TitleText(key: ValueKey(title), title: title),
                    ),
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
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _GreetingText(session: session),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Good morning, Akash" with the member pill, and under it the
/// collection's move today (from Home's chart data, so no extra request).
class _GreetingText extends StatelessWidget {
  const _GreetingText({required this.session});

  final UserSessionController session;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Obx(() {
          final user = session.user.value;
          // Free premium (is_free) counts: the backend treats it as subscribed.
          final premium =
              user != null && (user.hasActiveSubscription || user.isFreeUser);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  session.greetingText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                    color: AppColors.textGreeting,
                  ),
                ),
              ),
              if (user != null) ...[
                const SizedBox(width: 6),
                BottleMetaChip(label: premium ? 'PREMIUM' : 'FREE', gold: premium),
              ],
            ],
          );
        }),
        if (Get.isRegistered<HomeController>())
          _MoveLine(home: Get.find<HomeController>()),
      ],
    );
  }
}

class _MoveLine extends StatelessWidget {
  const _MoveLine({required this.home});

  final HomeController home;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final text = home.headerMoveText.value;
      final up = home.headerMoveUp.value;
      final color = up == null
          ? AppColors.textMuted
          : up
          ? AppColors.trendPositive
          : AppColors.marketTrendDown;
      return AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.medium),
        child: text.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                key: ValueKey(text),
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.micro().copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ),
      );
    });
  }
}

class _TitleText extends StatelessWidget {
  const _TitleText({super.key, required this.title});

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
