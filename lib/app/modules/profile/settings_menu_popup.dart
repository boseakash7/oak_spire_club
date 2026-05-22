import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../core/animations/app_dialog_transitions.dart';
import '../../core/animations/app_motion.dart';
import '../../core/analytics/app_analytics_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/app_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/animated_list_entrance.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/widgets/app_confirm_dialog.dart';
import '../../modules/navigation/bottom_nav_controller.dart';
import '../../modules/session/user_session_controller.dart';
import '../../routes/app_routes.dart';

const Color _kPopupBackdropOverlay = Color.fromRGBO(0, 0, 0, 0.72);
const double _kCardHorizontalPadding = 16;

/// Opens settings as an overlay (does not switch bottom-nav tab).
Future<void> showSettingsPopup(BuildContext context) async {
  if (Get.isRegistered<BottomNavController>()) {
    Get.find<BottomNavController>().settingsMenuOpen.value = true;
  }
  try {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close settings',
      barrierColor: Colors.transparent,
      transitionDuration: AppMotion.dialog,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return const _SettingsMenuDialog();
      },
      transitionBuilder: appDialogScaleFadeTransition,
    );
  } finally {
    if (Get.isRegistered<BottomNavController>()) {
      Get.find<BottomNavController>().settingsMenuOpen.value = false;
    }
  }
}

Future<void> settingsLogout() async {
  await AppStorage.clearSession();

  if (Get.isRegistered<UserSessionController>()) {
    Get.find<UserSessionController>().loadFromStorage();
  }

  Get.offAllNamed(AppRoutes.signUp);
}

class _SettingsMenuDialog extends StatelessWidget {
  const _SettingsMenuDialog();

  static const List<_SettingsRowData> _accountRows = [
    _SettingsRowData(
      icon: Icons.person_outline_rounded,
      title: 'Account',
      subtitle: 'Name, email & membership',
      analyticsKey: 'account',
    ),
    _SettingsRowData(
      icon: Icons.credit_card_rounded,
      title: 'Subscription',
      subtitle: 'Plans & billing',
      analyticsKey: 'subscription',
    ),
    _SettingsRowData(
      icon: Icons.notifications_outlined,
      title: 'Notifications',
      subtitle: 'Push & email alerts',
      analyticsKey: 'notifications',
    ),
    _SettingsRowData(
      icon: Icons.lock_outline_rounded,
      title: 'Privacy & security',
      subtitle: 'Password & data',
      analyticsKey: 'privacy_security',
    ),
  ];

  static const List<_SettingsRowData> _supportRows = [
    _SettingsRowData(
      icon: Icons.help_outline_rounded,
      title: 'Help & support',
      subtitle: 'FAQs and contact us',
      analyticsKey: 'help',
    ),
    _SettingsRowData(
      icon: Icons.info_outline_rounded,
      title: 'About',
      subtitle: 'App version & Oak Spire Club',
      analyticsKey: 'about',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : null;
    final user = session?.user.value;
    final userName = user?.name?.trim();
    final userEmail = user?.email?.trim();
    final maxH = MediaQuery.sizeOf(context).height * 0.82;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: const ColoredBox(color: _kPopupBackdropOverlay),
            ),
          ),
        ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400, maxHeight: maxH),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2E211C), Color(0xFF161010)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: AppColors.gold1.withValues(alpha: 0.12),
                        blurRadius: 24,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            _kCardHorizontalPadding,
                            12,
                            4,
                            4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: ShaderMask(
                                  shaderCallback: (bounds) => AppColors
                                      .goldGradient
                                      .createShader(bounds),
                                  blendMode: BlendMode.srcIn,
                                  child: Text(
                                    'Settings',
                                    style: AppTextStyles.heading32Bold()
                                        .copyWith(fontSize: 24, height: 1.1),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textCream,
                                  size: 26,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                              _kCardHorizontalPadding,
                              0,
                              _kCardHorizontalPadding,
                              16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _UserHeaderRow(
                                  name: userName,
                                  email: userEmail,
                                ),
                                const SizedBox(height: 16),
                                const _SectionLabel('Account'),
                                const SizedBox(height: 8),
                                ..._accountRows.asMap().entries.map(
                                  (e) => AnimatedListEntrance(
                                    index: e.key,
                                    child: _SettingsMenuRow(
                                      data: e.value,
                                      onTap: () => _onRowTap(context, e.value),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const _SectionLabel('Support & legal'),
                                const SizedBox(height: 8),
                                ..._supportRows.asMap().entries.map(
                                  (e) => AnimatedListEntrance(
                                    index: e.key + _accountRows.length,
                                    child: _SettingsMenuRow(
                                      data: e.value,
                                      onTap: () => _onRowTap(context, e.value),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedListEntrance(
                                  index:
                                      _accountRows.length + _supportRows.length,
                                  child: _SettingsMenuRow(
                                    data: const _SettingsRowData(
                                      icon: Icons.logout_rounded,
                                      title: 'Log out',
                                      subtitle: 'Sign out of this device',
                                      headerGoldStyle: true,
                                      analyticsKey: 'logout',
                                    ),
                                    onTap: () => _onLogoutTap(context),
                                  ),
                                ),
                                AnimatedListEntrance(
                                  index:
                                      _accountRows.length +
                                      _supportRows.length +
                                      1,
                                  child: _SettingsMenuRow(
                                    data: const _SettingsRowData(
                                      icon: Icons.delete_forever_outlined,
                                      title: 'Delete account',
                                      subtitle: 'Permanently remove your data',
                                      destructive: true,
                                      analyticsKey: 'delete_account',
                                    ),
                                    onTap: () => _onDeleteAccountTap(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onRowTap(BuildContext context, _SettingsRowData row) async {
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(
        AppAnalyticsController.to.logTap('settings_${row.analyticsKey}'),
      );
    }
    final route = switch (row.analyticsKey) {
      'subscription' => AppRoutes.subscription,
      'account' => AppRoutes.settingsAccount,
      'notifications' => AppRoutes.settingsNotifications,
      'privacy_security' => AppRoutes.settingsPrivacy,
      'help' => AppRoutes.settingsHelp,
      'about' => AppRoutes.settingsAbout,
      'delete_account' => AppRoutes.settingsDeleteAccount,
      _ => null,
    };

    if (route != null) {
      Navigator.of(context).pop();
      await Get.toNamed(route);
      return;
    }

    Navigator.of(context).pop();
    await AppSnackbar.info('${row.title} — coming soon');
  }

  Future<void> _onDeleteAccountTap(BuildContext context) async {
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(
        AppAnalyticsController.to.logTap('settings_delete_account'),
      );
    }
    Navigator.of(context).pop();
    await Get.toNamed(AppRoutes.settingsDeleteAccount);
  }

  Future<void> _onLogoutTap(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again to access your collection.',
      confirmLabel: 'Log out',
      cancelLabel: 'Stay',
      confirmIsDestructive: true,
    );
    if (!context.mounted) return;
    if (confirmed == true) {
      if (Get.isRegistered<AppAnalyticsController>()) {
        unawaited(AppAnalyticsController.to.logTap('settings_logout'));
      }
      Navigator.of(context).pop();
      await settingsLogout();
    }
  }
}

class _SettingsRowData {
  const _SettingsRowData({
    required this.icon,
    required this.title,
    this.subtitle,
    this.destructive = false,
    this.headerGoldStyle = false,
    required this.analyticsKey,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool destructive;
  final bool headerGoldStyle;
  final String analyticsKey;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.body16().copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
        color: AppColors.gold2,
      ),
    );
  }
}

class _UserHeaderRow extends StatelessWidget {
  const _UserHeaderRow({this.name, this.email});

  final String? name;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final displayName = (name != null && name!.isNotEmpty)
        ? name!
        : '${AppConstants.appName} member';
    final displayEmail = (email != null && email!.isNotEmpty)
        ? email!
        : 'Not signed in';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.goldGradient,
              border: Border.all(color: AppColors.goldBright, width: 1.5),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.black,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textCream,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsMenuRow extends StatelessWidget {
  const _SettingsMenuRow({required this.data, required this.onTap});

  final _SettingsRowData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = data.destructive
        ? AppColors.marketTrendDown
        : AppColors.white;
    final subtitleColor = data.destructive
        ? AppColors.marketTrendDown.withValues(alpha: 0.85)
        : data.headerGoldStyle
        ? AppColors.gold2.withValues(alpha: 0.75)
        : AppColors.textWolf;
    final iconBg = data.destructive
        ? AppColors.marketTrendDown.withValues(alpha: 0.18)
        : AppColors.menuRowSelected;
    final iconColor = data.destructive
        ? AppColors.marketTrendDown
        : AppColors.goldBright;

    final titleStyle = AppTextStyles.body16().copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: titleColor,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    data.headerGoldStyle
                        ? ShaderMask(
                            shaderCallback: (bounds) =>
                                AppColors.goldGradient.createShader(bounds),
                            blendMode: BlendMode.srcIn,
                            child: Text(
                              data.title,
                              style: titleStyle.copyWith(color: Colors.white),
                            ),
                          )
                        : Text(data.title, style: titleStyle),
                    if (data.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        data.subtitle!,
                        style: AppTextStyles.body16().copyWith(
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!data.destructive && !data.headerGoldStyle)
                SvgPicture.asset(
                  AppAssets.iconArrowRight,
                  height: 14,
                  width: 7,
                  colorFilter: ColorFilter.mode(
                    AppColors.textCream.withValues(alpha: 0.7),
                    BlendMode.srcIn,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
