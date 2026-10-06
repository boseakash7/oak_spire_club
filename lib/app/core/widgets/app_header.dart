import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../animations/app_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/greeting_formatter.dart';
import '../../modules/session/user_session_controller.dart';

/// Toolbar row height for [AppHeader] / shell [PreferredSize].
const double kShellAppBarHeight = kToolbarHeight;

/// Gap between the bottom of the shell app bar and the first line of tab
/// content. The scaffold lays out the body **below** the app bar
/// (`extendBodyBehindAppBar: false`), so this is only a small design inset.
const double kShellTabBodyContentTopGap = 12;

/// The shell's header: the user's icon with "Hello," over their first name
/// on the left, and their plan badge (PREMIUM / FREE) on the right. Both read
/// [UserSessionController.user], so `setUser` after a refresh updates them.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

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
      automaticallyImplyLeading: false,
      toolbarHeight: kShellAppBarHeight,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Obx(() {
          final user = session.user.value;
          // Free premium (is_free) counts: the backend treats it as subscribed.
          final premium =
              user != null && (user.hasActiveSubscription || user.isFreeUser);
          return Row(
            children: [
              const _UserIcon(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Greeting(
                  firstName: GreetingFormatter.firstNameFrom(
                    user?.name,
                    fallback: 'Collector',
                  ),
                ),
              ),
              if (user != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _PlanBadge(premium: premium),
              ],
            ],
          );
        }),
      ),
    );
  }
}

/// A person glyph in a gold-ringed circle.
class _UserIcon extends StatelessWidget {
  const _UserIcon();

  static const double _size = 38;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(1.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.goldGradient,
      ),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceChip,
        ),
        child: Center(
          child: Icon(Icons.person_rounded, size: 22, color: AppColors.gold2),
        ),
      ),
    );
  }
}

/// "Hello," over the first name.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello,',
          maxLines: 1,
          style: AppTextStyles.bodyS().copyWith(
            height: 1.1,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.medium),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.centerLeft,
            children: [...previous, ?current],
          ),
          child: Text(
            firstName,
            key: ValueKey(firstName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingM().copyWith(
              fontSize: 18,
              height: 1.1,
              color: AppColors.textCream,
            ),
          ),
        ),
      ],
    );
  }
}

/// PREMIUM (gold) or FREE. Cross-fades when the plan changes.
class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.premium});

  final bool premium;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.medium),
      child: Container(
        key: ValueKey(premium),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: premium ? AppColors.goldAccentGlow : AppColors.surfaceChip,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(
            color: premium
                ? AppColors.tagGoldBorder
                : AppColors.tagInactiveBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (premium) ...[
              const Icon(
                Icons.workspace_premium_rounded,
                size: 14,
                color: AppColors.goldRich,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              premium ? 'PREMIUM' : 'FREE',
              style: AppTextStyles.bodyS().copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: premium ? AppColors.goldRich : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
