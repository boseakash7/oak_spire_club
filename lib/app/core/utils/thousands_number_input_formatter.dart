import 'package:flutter/services.dart';

import 'price_formatter.dart';

/// Whole-dollar input with thousands separators as you type: `1450` → `1,450`.
/// Used by the add-to-collection price field and the deal check.
class ThousandsNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = PriceFormatter.normalizeForApi(newValue.text);
    if (normalized == null) {
      return const TextEditingValue(text: '');
    }
    final formatted = PriceFormatter.format(normalized, withSymbol: false);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
