/// A bottle's recent prices for a list-row sparkline, from
/// `bluebook/sparklines`. History is change-only, so [prices] are the price
/// in force at the window's start, each change, and the price at its end.
class PriceSparkline {
  const PriceSparkline({required this.prices, this.changePct});

  final List<double> prices;

  /// Last against first, as a percentage; null when the first price is 0.
  final double? changePct;

  bool get isEmpty => prices.length < 2;
  bool get isUp => (changePct ?? 0) > 0;
  bool get isDown => (changePct ?? 0) < 0;

  /// Tolerates the API's stringly-typed numbers. `points` holds `{d, p}` maps.
  factory PriceSparkline.fromJson(Map<String, dynamic> json) {
    final raw = json['points'];
    final prices = <double>[];
    if (raw is List) {
      for (final point in raw) {
        final v = point is Map ? point['p'] : point;
        final price = double.tryParse(v?.toString() ?? '');
        if (price != null) prices.add(price);
      }
    }
    return PriceSparkline(
      prices: prices,
      changePct: double.tryParse(json['change_pct']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'points': [
      for (final p in prices) {'p': p},
    ],
    'change_pct': changePct,
  };
}
