import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CommonPrimaryButton extends StatelessWidget {
  const CommonPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.textStyle,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final TextStyle? textStyle;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: (textStyle ?? AppTextStyles.button20Bold()).color,
                  ),
                )
              : Text(label, style: textStyle ?? AppTextStyles.button20Bold()),
        ),
      ),
    );
  }
}

