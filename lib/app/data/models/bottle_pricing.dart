/// What a bottle's price rests on: the API's `pricing` object, on every
/// bottle endpoint (oakspireweb `BlueBookHelper::pricing`).
///
/// ```json
/// "pricing": { "confidence": "low", "basis": "manual",
///              "observation_count": 1, "priced_at": 1790260000 }
/// ```
///
/// The presentation rules (ai-features-plan.md §2.5) read from here:
/// a `manual` price is an Oak Spire price, never "market value"; a `retail`
/// price is below shelf price; `low` / `stale` / null confidence is thin.
class BottlePricing {
  const BottlePricing({
    this.confidence,
    this.basis,
    this.observationCount,
    this.pricedAt,
  });

  /// `high` | `medium` | `low` | `stale`, or null for a legacy price the
  /// price bot never touched.
  final String? confidence;

  /// `sold` | `retail` | `manual` | `ask` | `bid`, or null.
  final String? basis;

  final int? observationCount;
  final DateTime? pricedAt;

  static BottlePricing? fromJson(dynamic json) {
    if (json is! Map) return null;
    final pricedAt = int.tryParse(_s(json['priced_at']) ?? '');
    return BottlePricing(
      confidence: _s(json['confidence'])?.toLowerCase(),
      basis: _s(json['basis'])?.toLowerCase(),
      observationCount: int.tryParse(_s(json['observation_count']) ?? ''),
      pricedAt: pricedAt == null || pricedAt <= 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(pricedAt * 1000),
    );
  }

  /// Backed by market observations rather than an admin's entry.
  bool get isMarket => basis == 'sold' || basis == 'ask' || basis == 'bid';

  bool get isOakSpirePrice => basis == 'manual';

  /// Thin evidence: say so next to the number.
  bool get isThin =>
      confidence == null || confidence == 'low' || confidence == 'stale';

  /// Short label for the price's source.
  String get label {
    if (isOakSpirePrice) return 'Oak Spire price';
    if (basis == 'retail') return 'Retail';
    if (isMarket) return confidence == 'stale' ? 'Market · dated' : 'Market';
    return 'Estimate';
  }

  static String? _s(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty || s == 'null' ? null : s;
  }
}
