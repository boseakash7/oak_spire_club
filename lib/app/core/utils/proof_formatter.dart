/// Display helper for bottle proof / ABV from API (`proof`, `bottle_proof`, etc.).
abstract final class ProofFormatter {
  ProofFormatter._();

  /// Returns trimmed API text unchanged. Null when [raw] is missing.
  static String? formatLabel(String? raw) {
    final p = raw?.trim();
    if (p == null || p.isEmpty || p == 'null') return null;
    return p;
  }

  /// Same as [formatLabel], with [fallback] when API has no proof (default `—`).
  static String formatLabelOrFallback(String? raw, {String fallback = '—'}) {
    return formatLabel(raw) ?? fallback;
  }
}
