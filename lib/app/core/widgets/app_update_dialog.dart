import 'package:flutter/material.dart';

import '../animations/app_motion.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'show_app_dialog.dart';

/// Shows an app-update dialog styled like other Oak Spire popups.
///
/// Returns `true` when the user may continue into the app (optional update +
/// "Later"). Returns `false` when the user must update (forced) or chose
/// "Update" (they stay on splash until they install a new build).
Future<bool> showAppUpdateDialog(
  BuildContext context, {
  required bool isForced,
  required VoidCallback onUpdate,
}) {
  return showAppAnimatedDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: AppMotion.dialog,
    builder: (ctx) => _AppUpdateDialogBody(
      isForced: isForced,
      onUpdate: onUpdate,
      onLater: isForced
          ? null
          : () {
              Navigator.of(ctx).pop(true);
            },
    ),
  ).then((value) => value ?? false);
}

class _AppUpdateDialogBody extends StatelessWidget {
  const _AppUpdateDialogBody({
    required this.isForced,
    required this.onUpdate,
    this.onLater,
  });

  final bool isForced;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    final title = isForced ? 'Update required' : 'Update available';
    final message = isForced
        ? 'A new version of ${AppConstants.appName} is required to continue. '
            'Please update from the store to keep using the app.'
        : 'A new version of ${AppConstants.appName} is available with '
            'improvements and fixes.';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.cardSurfaceGradient,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.navBarBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceChip,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.tagGoldBorder),
                    ),
                    child: Icon(
                      Icons.system_update_alt_rounded,
                      size: 26,
                      color: AppColors.gold2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading32Bold().copyWith(
                      fontSize: 22,
                      height: 1.15,
                      color: AppColors.textCream,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body16().copyWith(
                      color: AppColors.textMuted,
                      height: 1.35,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 26),
                  if (onLater != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: onLater,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textCream,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Later',
                          style: AppTextStyles.body16().copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textCream,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: AppColors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onUpdate,
                        child: Text(
                          'Update now',
                          style: AppTextStyles.button20Bold().copyWith(
                            fontSize: 17,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
