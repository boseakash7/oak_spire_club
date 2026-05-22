/// Shared parsing for API `proof` and related keys on bottle payloads.
abstract final class ProofJson {
  ProofJson._();

  static const List<String> keys = [
    'proof',
    'bottle_proof',
    'alcohol_proof',
    'abv',
    'proof_value',
    'strength',
    'alcohol',
  ];

  /// Reads the first non-empty proof-like value from a single JSON object.
  static String? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && s != 'null') return s;
    }
    return null;
  }

  /// Root item map, then nested `bluebook`, then `bluebook.product`.
  static String? coalesce(
    Map<String, dynamic> json, {
    Map<String, dynamic>? bluebook,
  }) {
    final root = fromMap(json);
    if (root != null) return root;
    final fromBb = fromMap(bluebook);
    if (fromBb != null) return fromBb;
    final product = bluebook?['product'];
    if (product is Map) {
      return fromMap(Map<String, dynamic>.from(product));
    }
    return null;
  }
}
