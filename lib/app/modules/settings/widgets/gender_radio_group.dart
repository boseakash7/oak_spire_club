import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Gender values accepted by `POST auth/update` (form: gender=male|female|other|prefer not to say).
abstract final class GenderOption {
  static const male = 'male';
  static const female = 'female';
  static const other = 'other';
  static const preferNotToSay = 'prefer not to say';

  static const labels = <String, String>{
    male: 'Male',
    female: 'Female',
    other: 'Other',
    preferNotToSay: 'Prefer not to say',
  };

  static const values = [male, female, other, preferNotToSay];

  /// Maps API / legacy stored values to a canonical option for the UI.
  static String? normalize(String? raw) {
    if (raw == null) return null;
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;
    switch (s) {
      case male:
        return male;
      case female:
        return female;
      case other:
        return other;
      case 'prefer not to say':
      case 'prefer_not_to_say':
      case 'prefer-not-to-say':
        return preferNotToSay;
      default:
        return values.contains(s) ? s : null;
    }
  }
}

class GenderRadioGroup extends StatelessWidget {
  const GenderRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in GenderOption.labels.entries)
          _GenderTile(
            label: entry.value,
            selected: value == entry.key,
            onTap: () => onChanged(entry.key),
          ),
      ],
    );
  }
}

class _GenderTile extends StatelessWidget {
  const _GenderTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.gold1 : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.goldBright : AppColors.border,
                    width: selected ? 0 : 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.circle,
                        size: 10,
                        color: AppColors.black,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTextStyles.body16().copyWith(
                  fontSize: 15,
                  color: selected ? AppColors.textCream : AppColors.white,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
