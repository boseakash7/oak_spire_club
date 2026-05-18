import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PriceFormatter {
  PriceFormatter._();

  static String format(String? value, {bool withSymbol = true}) {
    final normalized = _normalizeDigits(value);
    if (normalized == null) return '—';
    final formatted = _withThousands(normalized);
    return withSymbol ? '\$$formatted' : formatted;
  }

  /// Whole-dollar string for API / form persistence. Must treat `30.00` as 30,
  /// not digit-stripping to `3000` (same pitfall as [format] had for decimals).
  static String? normalizeForApi(String? value) {
    return _normalizeDigits(value);
  }

  /// Whole dollars for UI. Accepts plain integers (`434`) or decimals (`30.00`);
  /// decimals must be parsed as numbers—stripping non-digits would turn `30.00` into `3000`.
  static String? _normalizeDigits(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return null;
    final n = double.tryParse(cleaned);
    if (n == null) return null;
    return n.round().toString();
  }

  static String _withThousands(String digits) {
    final chars = digits.split('').reversed.toList();
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(chars[i]);
    }
    return buffer.toString().split('').reversed.join();
  }

  /// API `price_movement` (e.g. `"0.00"`, `"-7.5"`, `"3.2%"`) → display label.
  static String formatPriceMovementLabel(String? raw) {
    final s = raw?.trim();
    if (s == null || s.isEmpty || s == 'null') return '—';
    if (s.contains('%')) {
      return s;
    }
    final n = double.tryParse(s.replaceAll(RegExp(r'[^\d.+-]'), ''));
    if (n == null) {
      return s;
    }
    final sign = n > 0 ? '+' : '';
    final decimals = n == n.roundToDouble() ? 0 : 2;
    return '$sign${n.toStringAsFixed(decimals)}%';
  }

  /// Parsed numeric `price_movement` for sorting/comparison (e.g. home top moved).
  static double? parsePriceMovementValue(String? raw) =>
      _parsePriceMovementNumber(raw);

  static double? _parsePriceMovementNumber(String? raw) {
    final s = raw?.trim();
    if (s == null || s.isEmpty || s == 'null') return null;
    return double.tryParse(s.replaceAll(RegExp(r'[^\d.+-]'), ''));
  }

  static Color priceMovementColor(String? raw) {
    final n = _parsePriceMovementNumber(raw);
    if (n == null) return AppColors.textWolf;
    if (n > 0) return AppColors.trendPositive;
    if (n < 0) return AppColors.marketTrendDown;
    return AppColors.textWolf;
  }

  /// Arrow asset key: `up` | `down` | `flat` for [AppAssets.iconArrowUp] etc.
  static String priceMovementArrowKind(String? raw) {
    final n = _parsePriceMovementNumber(raw);
    if (n == null || n == 0) return 'flat';
    return n > 0 ? 'up' : 'down';
  }
}
