double? _num(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty || s == 'null') return null;
  return double.tryParse(s);
}

/// A bottle's nightly market stats, the API's `market` object
/// (oakspireweb `bluebook_market_stats`). Every field may be null: no price
/// recorded that long ago, or a server without the stats.
class BottleMarketStats {
  const BottleMarketStats({
    this.change30d,
    this.change90d,
    this.change365d,
    this.high365d,
    this.low365d,
  });

  /// Percent change against the price in force 30 days ago.
  final double? change30d;
  final double? change90d;
  final double? change365d;
  final double? high365d;
  final double? low365d;

  /// The change over [days] (30, 90 or 365), or null.
  double? changeOver(int days) => switch (days) {
    30 => change30d,
    90 => change90d,
    365 => change365d,
    _ => null,
  };

  static BottleMarketStats? fromJson(dynamic json) {
    if (json is! Map) return null;
    return BottleMarketStats(
      change30d: _num(json['change_30d']),
      change90d: _num(json['change_90d']),
      change365d: _num(json['change_365d']),
      high365d: _num(json['high_365d']),
      low365d: _num(json['low_365d']),
    );
  }
}
