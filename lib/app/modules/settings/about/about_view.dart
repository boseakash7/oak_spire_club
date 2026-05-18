import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../widgets/settings_scaffold.dart';

class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  String _version = '—';
  String _build = '—';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = info.version;
      _build = info.buildNumber;
    });
  }

  void _openLegal({required String title, required String url}) {
    Get.toNamed(
      AppRoutes.settingsLegalWeb,
      arguments: {'title': title, 'url': url},
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'About',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsSurfaceCard(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    AppAssets.appIc,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.heading32Bold().copyWith(
                    fontSize: 22,
                    color: AppColors.textCream,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Version $_version (build $_build)',
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Track your whiskey collection, follow market benchmarks, and discover bottles that match your taste.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 14,
                    color: AppColors.textWolf,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SettingsSectionLabel('Legal'),
          _AboutLinkRow(
            icon: Icons.description_outlined,
            title: 'Terms of Use',
            onTap: () => _openLegal(
              title: 'Terms of Use',
              url: AppConstants.termsUrl,
            ),
          ),
          const SizedBox(height: 10),
          _AboutLinkRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _openLegal(
              title: 'Privacy Policy',
              url: AppConstants.privacyUrl,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '© ${DateTime.now().year} ${AppConstants.appName}. All rights reserved.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body16().copyWith(
              fontSize: 12,
              color: AppColors.textWolf,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutLinkRow extends StatelessWidget {
  const _AboutLinkRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kSettingsCardBorder),
            gradient: AppColors.cardSurfaceGradient,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.goldBright, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textCream.withValues(alpha: 0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
