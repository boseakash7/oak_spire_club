import 'package:flutter/material.dart';

import '../animations/app_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_haptics.dart';

/// A compact segmented selector (chart ranges: 1M / 3M / 6M / 1Y) whose
/// gold pill slides to the chosen segment.
class AppSegmentedRange<T> extends StatelessWidget {
  const AppSegmentedRange({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.segmentWidth = 38,
    this.height = 32,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;
  final double segmentWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(selected);
    final count = values.length;
    final duration = AppMotion.of(context, AppMotion.chip);

    return Container(
      height: height,
      width: segmentWidth * count + 6,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceChip,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: AppColors.tagInactiveBorder),
      ),
      child: Stack(
        children: [
          if (index >= 0)
            AnimatedAlign(
              duration: duration,
              curve: AppMotion.emphasizedDecelerate,
              alignment: Alignment(
                count <= 1 ? 0 : -1 + 2 * index / (count - 1),
                0,
              ),
              child: Container(
                width: segmentWidth,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: const [
                    BoxShadow(color: AppColors.goldGlow, blurRadius: 10),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              for (final value in values)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: value == selected,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: value == selected
                          ? null
                          : () {
                              AppHaptics.selection();
                              onChanged(value);
                            },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: duration,
                          style: AppTextStyles.label().copyWith(
                            color: value == selected
                                ? AppColors.black
                                : AppColors.textMuted,
                            fontWeight: value == selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          child: Text(labelOf(value)),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
