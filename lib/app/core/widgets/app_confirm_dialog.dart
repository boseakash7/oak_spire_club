import 'package:flutter/material.dart';

import '../animations/app_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'show_app_dialog.dart';

/// Styled confirmation dialog using app colors — use anywhere via [showAppConfirmDialog].
Future<bool?> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool confirmIsDestructive = false,
  bool barrierDismissible = true,
}) {
  return showAppAnimatedDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: AppMotion.dialog,
    builder: (ctx) => _AppConfirmDialogBody(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      confirmIsDestructive: confirmIsDestructive,
    ),
  );
}

class _AppConfirmDialogBody extends StatelessWidget {
  const _AppConfirmDialogBody({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.confirmIsDestructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool confirmIsDestructive;

  static const Color _cardTop = Color(0xFF271C16);
  static const Color _cardBottom = Color(0xFF161010);
  static const Color _border = Color(0xFF4A342E);
  static const Color _cream = Color(0xFFF1E8BE);
  static const Color _muted = Color(0xFF9D9C9C);

  @override
  Widget build(BuildContext context) {
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
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_cardTop, _cardBottom],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading32Bold().copyWith(
                      fontSize: 22,
                      height: 1.15,
                      color: _cream,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body16().copyWith(
                      color: _muted,
                      height: 1.35,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _cream,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        cancelLabel,
                        style: AppTextStyles.body16().copyWith(
                          fontWeight: FontWeight.w600,
                          color: _cream,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: confirmIsDestructive
                            ? null
                            : AppColors.goldGradient,
                        color: confirmIsDestructive
                            ? const Color(0xFF8B2929)
                            : null,
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
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          confirmLabel,
                          style: AppTextStyles.button20Bold().copyWith(
                            fontSize: 17,
                            color: confirmIsDestructive
                                ? Colors.white
                                : AppColors.black,
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
