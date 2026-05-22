import 'package:flutter/material.dart';

import '../animations/app_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CommonPrimaryButton extends StatefulWidget {
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
  State<CommonPrimaryButton> createState() => _CommonPrimaryButtonState();
}

class _CommonPrimaryButtonState extends State<CommonPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isLoading && widget.onPressed != null;
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: AppMotion.press,
      curve: AppMotion.pressCurve,
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: enabled ? widget.onPressed : null,
              onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
              onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
              onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color:
                              (widget.textStyle ?? AppTextStyles.button20Bold())
                                  .color,
                        ),
                      )
                    : Text(
                        widget.label,
                        style:
                            widget.textStyle ?? AppTextStyles.button20Bold(),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
