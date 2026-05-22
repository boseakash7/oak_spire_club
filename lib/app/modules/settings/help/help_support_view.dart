import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/widgets/animated_list_entrance.dart';
import '../widgets/settings_scaffold.dart';

class HelpSupportView extends StatelessWidget {
  const HelpSupportView({super.key});

  // Future<void> _openWhatsApp() async {
  //   final phone = AppConstants.supportWhatsApp.replaceAll(RegExp(r'\D'), '');
  //   final uri = Uri.parse('https://wa.me/$phone');
  //   if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
  //     await AppSnackbar.error('Could not open WhatsApp.');
  //   }
  // }

  Future<void> _openEmail() async {
    final subject = Uri.encodeComponent('${AppConstants.appName} — Help');
    final body = Uri.encodeComponent(
      'Hi Oak Spire Club support,\n\n\n',
    );
    final uri = Uri.parse(
      'mailto:${AppConstants.supportEmail}?subject=$subject&body=$body',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await AppSnackbar.error(
        'No mail app found. Email us at ${AppConstants.supportEmail}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Help & support',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reach our team by email. We typically reply within one business day.',
            style: AppTextStyles.body16().copyWith(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          // AnimatedListEntrance(
          //   index: 0,
          //   child: _ContactCard(
          //     icon: Icons.chat_rounded,
          //     iconColor: const Color(0xFF25D366),
          //     title: 'WhatsApp',
          //     subtitle: 'Chat with support',
          //     detail: '+${AppConstants.supportWhatsApp}',
          //     onTap: _openWhatsApp,
          //   ),
          // ),
          // const SizedBox(height: 14),
          AnimatedListEntrance(
            index: 0,
            child: _ContactCard(
              icon: Icons.mail_outline_rounded,
              iconColor: AppColors.goldBright,
              title: 'Email',
              subtitle: 'Send us a message',
              detail: AppConstants.supportEmail,
              onTap: _openEmail,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kSettingsCardBorder),
            gradient: AppColors.cardSurfaceGradient,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body16().copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.body16().copyWith(
                        fontSize: 13,
                        color: AppColors.textWolf,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      detail,
                      style: AppTextStyles.body16().copyWith(
                        fontSize: 13,
                        color: AppColors.textCream,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textCream.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
