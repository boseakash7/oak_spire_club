import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../platform/app_platform.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Picks a date the way each platform expects: a wheel in a bottom sheet on
/// iOS, the Material calendar dialog on Android. Returns null if dismissed.
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  final initial = initialDate.isBefore(firstDate)
      ? firstDate
      : initialDate.isAfter(lastDate)
      ? lastDate
      : initialDate;

  if (!AppPlatform.isCupertino) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (sheetContext) => _CupertinoDateSheet(
      initial: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

class _CupertinoDateSheet extends StatefulWidget {
  const _CupertinoDateSheet({
    required this.initial,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_CupertinoDateSheet> createState() => _CupertinoDateSheetState();
}

class _CupertinoDateSheetState extends State<_CupertinoDateSheet> {
  late DateTime _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: AppColors.menuSurface,
        borderRadius: AppRadii.sheetTop,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.bodyL().copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const Spacer(),
                CupertinoButton(
                  onPressed: () => Navigator.of(context).pop(_value),
                  child: Text(
                    'Done',
                    style: AppTextStyles.bodyL().copyWith(
                      color: AppColors.gold2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  brightness: Brightness.dark,
                  primaryColor: AppColors.gold2,
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: widget.initial,
                  minimumDate: widget.firstDate,
                  maximumDate: widget.lastDate,
                  onDateTimeChanged: (v) => _value = v,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
