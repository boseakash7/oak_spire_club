import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Text field styling shared with [AddCollectionView] form rows.
class CollectionFormField extends StatelessWidget {
  const CollectionFormField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.minLines = 1,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.prefixText,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.onSubmitted,
    this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int minLines;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? prefixText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  static const Color fillColor = Color(0xFF10090B);
  static const Color borderEnabled = Color(0xFF414141);
  static const Color borderFocused = Color(0xFF585858);
  static const Color borderError = Color(0xFFB3261E);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      style: AppTextStyles.body16().copyWith(
        fontSize: 14,
        color: AppColors.white,
      ),
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        prefixIcon: prefixIcon,
        prefixText: prefixText,
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: AppTextStyles.body16().copyWith(
          fontSize: 16,
          color: AppColors.white,
        ),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: borderEnabled),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: borderEnabled),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: borderFocused),
        ),
        errorText: errorText,
        errorStyle: AppTextStyles.body16().copyWith(
          fontSize: 12,
          color: borderError,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: borderError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: borderError),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
