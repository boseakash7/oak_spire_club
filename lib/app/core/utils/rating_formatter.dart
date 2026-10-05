/// Bottle ratings, shown out of 10 everywhere.
///
/// The backend stores `bluebook.rating` out of 100 (the admin form's unit is
/// `/100`) and saves an empty rating as `0`, so `0` means "not rated". The
/// collection average (`collection_rating_percentage`) is on the same scale.
abstract final class RatingFormatter {
  RatingFormatter._();

  /// The rating on a 0–10 scale, or null when the bottle is not rated.
  static double? outOfTen(Object? raw) {
    final s = raw?.toString().trim();
    if (s == null || s.isEmpty || s == 'null') return null;
    final v = double.tryParse(s);
    if (v == null || v <= 0) return null;
    return (v / 10).clamp(0.0, 10.0);
  }

  /// `9.2`, `9` (a trailing `.0` is dropped), or `—` when not rated.
  static String label(Object? raw) {
    final v = outOfTen(raw);
    if (v == null) return '—';
    final fixed = v.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

  /// `9.2/10`, or `—` when not rated.
  static String labelOutOfTen(Object? raw) {
    final l = label(raw);
    return l == '—' ? l : '$l/10';
  }
}
