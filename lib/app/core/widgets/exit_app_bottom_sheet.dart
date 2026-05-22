import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'show_app_dialog.dart';

/// Confirms exit before closing the app (used on home tab back press).
Future<bool> showExitAppBottomSheet(BuildContext context) async {
  final result = await showAppAnimatedBottomSheet<bool>(
    context: context,
    builder: (ctx) {
      final bottomInset = MediaQuery.paddingOf(ctx).bottom;
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppColors.cardSurfaceGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(23, 22, 23, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Exit app?',
                style: AppTextStyles.body16().copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to close Oak Spire Club?',
                style: AppTextStyles.body16().copyWith(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _SheetButton(
                      label: 'Stay',
                      outlined: true,
                      onTap: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetButton(
                      label: 'Exit',
                      onTap: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result == true;
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: outlined ? null : AppColors.goldGradient,
            border: outlined
                ? Border.all(color: AppColors.tagInactiveBorder)
                : null,
            color: outlined ? AppColors.surfaceChip : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.body16().copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: outlined ? AppColors.textCream : AppColors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
