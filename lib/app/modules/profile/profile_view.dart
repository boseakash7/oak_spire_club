import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/storage/app_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_confirm_dialog.dart';
import '../../core/widgets/common_primary_button.dart';
import '../../modules/session/user_session_controller.dart';
import '../../routes/app_routes.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  Future<void> _logout() async {
    await AppStorage.clearUserId();
    await AppStorage.clearUser();

    if (Get.isRegistered<UserSessionController>()) {
      Get.find<UserSessionController>().loadFromStorage();
    }

    Get.offAllNamed(AppRoutes.signUp);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 120, 24, 90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profile',
              style: AppTextStyles.heading32Bold().copyWith(fontSize: 18),
            ),
            const SizedBox(height: 18),
            CommonPrimaryButton(
              label: 'Logout',
              onPressed: () async {
                final confirmed = await showAppConfirmDialog(
                  context,
                  title: 'Log out?',
                  message:
                      'You will need to sign in again to access your collection.',
                  confirmLabel: 'Log out',
                  cancelLabel: 'Stay',
                );
                if (!context.mounted) return;
                if (confirmed == true) {
                  await _logout();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

