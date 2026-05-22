import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

/// iOS-style chevron back control for app bars and custom headers.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.color = AppColors.textGreeting,
    this.iconSize = 20,
    this.constraints = const BoxConstraints.tightFor(width: 34, height: 34),
  });

  final VoidCallback? onPressed;
  final Color color;
  final double iconSize;
  final BoxConstraints constraints;

  void _defaultPop(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => _defaultPop(context),
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        color: color,
        size: iconSize,
      ),
      padding: EdgeInsets.zero,
      constraints: constraints,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }
}

/// Standard dark app bar with an iOS-style back button when the route can pop.
class AppScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppScreenAppBar({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.onBack,
    this.showBack = true,
  });

  final Widget title;
  final bool centerTitle;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      backgroundColor: AppColors.surfaceDeep,
      surfaceTintColor: AppColors.surfaceDeep,
      elevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: showBack && canPop
          ? AppBackButton(onPressed: onBack)
          : null,
      title: title,
    );
  }
}
