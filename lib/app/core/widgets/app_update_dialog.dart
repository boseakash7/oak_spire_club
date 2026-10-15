import 'package:flutter/material.dart';

import '../animations/app_motion.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'show_app_dialog.dart';
import '../theme/app_spacing.dart';

/// The optional update: version, "What's new" and Later / Update now. A
/// forced update is the `/update-required` screen instead.
///
/// Returns `true` for "Update now". "Later" and Back return `false`, and the
/// app goes on; it asks again at the next launch.
Future<bool> showAppUpdateDialog(
  BuildContext context, {
  String? versionName,
  List<String> notes = const [],
}) {
  return showAppAnimatedDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: AppMotion.dialog,
    builder: (ctx) => _AppUpdateDialogBody(
      versionName: versionName,
      notes: notes,
      onUpdate: () => Navigator.of(ctx).pop(true),
      onLater: () => Navigator.of(ctx).pop(false),
    ),
  ).then((value) => value ?? false);
}

/// At most this many notes show; the rest are in the store listing.
const int _kMaxNotes = 5;

class _AppUpdateDialogBody extends StatelessWidget {
  const _AppUpdateDialogBody({
    required this.versionName,
    required this.notes,
    required this.onUpdate,
    required this.onLater,
  });

  final String? versionName;
  final List<String> notes;
  final VoidCallback onUpdate;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final shown = notes.take(_kMaxNotes).toList();
    final noteStyle = AppTextStyles.body16().copyWith(
      color: AppColors.textMuted,
      height: 1.35,
      fontSize: 14,
    );

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
            // Scrolls only when long notes meet a short screen.
            child: SingleChildScrollView(
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
                    'Update available',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading32Bold().copyWith(
                      fontSize: 22,
                      height: 1.15,
                      color: AppColors.textCream,
                    ),
                  ),
                  if (versionName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Version $versionName',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyS().copyWith(
                        fontSize: 13,
                        color: AppColors.goldBright,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (shown.isEmpty)
                    Text(
                      'A new version of ${AppConstants.appName} is out with '
                      'improvements and fixes.',
                      textAlign: TextAlign.center,
                      style: noteStyle.copyWith(fontSize: 15),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "WHAT'S NEW",
                            style: AppTextStyles.bodyS().copyWith(
                              fontSize: 10.5,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWolf,
                            ),
                          ),
                          for (final note in shown)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 7,
                                      right: 8,
                                    ),
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: AppColors.gold2,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Text(note, style: noteStyle)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: AppButtonSize.regular,
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
                  SizedBox(
                    width: double.infinity,
                    height: AppButtonSize.regular,
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
                            fontSize: AppButtonSize.labelSize,
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
