import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CommonTextField extends StatefulWidget {
  const CommonTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.showVisibilityToggle = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final String hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  /// When true (usually with [obscureText]), shows an eye icon to show/hide the value.
  final bool showVisibilityToggle;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<CommonTextField> createState() => _CommonTextFieldState();
}

class _CommonTextFieldState extends State<CommonTextField> {
  late bool _obscure;

  bool get _passwordLike =>
      widget.showVisibilityToggle || widget.obscureText;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  void didUpdateWidget(CommonTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showVisibilityToggle &&
        oldWidget.obscureText != widget.obscureText) {
      _obscure = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveObscure =
        widget.showVisibilityToggle ? _obscure : widget.obscureText;

    return SizedBox(
      height: 45,
      child: TextField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        obscureText: effectiveObscure,
        autocorrect: !_passwordLike,
        enableSuggestions: !_passwordLike,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        style: AppTextStyles.body16(),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.panel,
          hintText: widget.hintText,
          hintStyle: AppTextStyles.body16().copyWith(
            color: AppColors.white.withValues(alpha: 0.9),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          suffixIcon: widget.showVisibilityToggle
              ? IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 40,
                  ),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 22,
                    color: AppColors.white.withValues(alpha: 0.75),
                  ),
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.border, width: 1.2),
          ),
        ),
      ),
    );
  }
}
