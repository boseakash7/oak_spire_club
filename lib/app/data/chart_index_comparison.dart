import 'dart:math' as math;

/// Index-style chart comparison (bourboneur `chart_page/chart.dart`).
///
/// Each series is rebased so its first point in the window = 100, then
/// `(price / firstPrice) * 100`, so the collection's value and an index (the
/// Oak Spire Index on Collection) compare on one axis as relative
/// performance, not raw dollars.
class ChartIndexComparison {
  ChartIndexComparison._();

  static const int defaultPointLimit = 9;

  static List<Map<String, dynamic>> parsePriceSeries(dynamic raw) {
    if (raw is! List) return [];
    final points = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map && item['price'] != null) {
        final p = double.tryParse(item['price'].toString());
        if (p != null) {
          points.add(Map<String, dynamic>.from(item));
        }
      }
    }
    return points;
  }

  static List<Map<String, dynamic>> lastPoints(
    List<Map<String, dynamic>> points, {
    int maxPoints = defaultPointLimit,
  }) {
    if (points.length <= maxPoints) return points;
    return points.sublist(points.length - maxPoints);
  }

  /// Rebase series to 100 at the first point (bourboneur normalize block).
  static List<double> normalizeToIndex100(List<Map<String, dynamic>> points) {
    if (points.isEmpty) return [];
    final first = double.tryParse(points.first['price']?.toString() ?? '') ?? 0;
    if (first <= 0) return List<double>.filled(points.length, 100);
    return points.map((e) {
      final p = double.tryParse(e['price']?.toString() ?? '') ?? 0;
      return (p / first) * 100;
    }).toList();
  }

  /// The index's value as of each market date: its latest point on or before
  /// that date (dates are `Y-m-d`, so they compare as strings). Market dates
  /// before the index's first point take that first value, so the lines start
  /// together. Empty when the index has no points.
  static List<Map<String, dynamic>> alignIndexToMarketDates({
    required List<Map<String, dynamic>> marketPoints,
    required List<Map<String, dynamic>> indexPoints,
  }) {
    if (marketPoints.isEmpty) return [];

    final index = <(String, double)>[
      for (final p in indexPoints)
        if ((p['date']?.toString() ?? '').isNotEmpty &&
            double.tryParse(p['price']?.toString() ?? '') != null)
          (p['date'].toString(), double.parse(p['price'].toString())),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    if (index.isEmpty) return [];

    var j = 0;
    return [
      for (final m in marketPoints)
        () {
          final date = m['date']?.toString() ?? '';
          while (j + 1 < index.length && index[j + 1].$1.compareTo(date) <= 0) {
            j++;
          }
          return {'date': date, 'price': index[j].$2.toString()};
        }(),
    ];
  }

  static List<double> _pricesFromPoints(List<Map<String, dynamic>> points) {
    return points
        .map((e) => double.tryParse(e['price']?.toString() ?? '') ?? 0)
        .toList();
  }

  static List<String> _datesFromPoints(List<Map<String, dynamic>> points) {
    return points.map((e) => e['date']?.toString() ?? '').toList();
  }

  /// Market + BSMI index lines, raw prices for tooltips, and Y bounds.
  static ChartComparedSeriesResult buildComparedSeries({
    required List<Map<String, dynamic>> marketPoints,
    required List<Map<String, dynamic>> indexPoints,
    required int maxPoints,
  }) {
    final window = marketPoints.length <= maxPoints
        ? marketPoints
        : lastPoints(marketPoints, maxPoints: maxPoints);
    if (window.isEmpty) {
      return const ChartComparedSeriesResult.empty();
    }

    final marketIndex = normalizeToIndex100(window);

    List<Map<String, dynamic>> bsmiWindow = alignIndexToMarketDates(
      marketPoints: window,
      indexPoints: indexPoints,
    );
    if (bsmiWindow.isEmpty && indexPoints.isNotEmpty) {
      final tail = lastPoints(indexPoints, maxPoints: window.length);
      if (tail.length == window.length) bsmiWindow = tail;
    }

    final bsmiIndex = bsmiWindow.isEmpty
        ? <double>[]
        : normalizeToIndex100(bsmiWindow);

    final bounds = _indexAxisBounds([...marketIndex, ...bsmiIndex]);
    return ChartComparedSeriesResult(
      marketIndex: marketIndex,
      bsmiIndex: bsmiIndex,
      dates: _datesFromPoints(window),
      marketPrices: _pricesFromPoints(window),
      bsmiPrices: bsmiWindow.isEmpty
          ? <double>[]
          : _pricesFromPoints(bsmiWindow),
      minY: bounds.$1,
      maxY: bounds.$2,
    );
  }

  /// Y axis anchored at the data minimum (bottom-left), with headroom only above.
  /// Bourboneur leaves [minY]/[maxY] unset so fl_chart uses this tight range.
  static (double, double) _indexAxisBounds(List<double> values) {
    if (values.isEmpty) return (90, 110);
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final span = maxV - minV;
    if (span < 1) {
      // Bourboneur `priceGap == 0 ? 5` — small band above the floor, not centered on 100.
      return (math.max(0, minV), minV + 5);
    }
    final topPad = span * 0.12;
    return (math.max(0, minV), maxV + topPad);
  }
}

/// Normalized chart series plus raw values for touch tooltips.
class ChartComparedSeriesResult {
  const ChartComparedSeriesResult({
    required this.marketIndex,
    required this.bsmiIndex,
    required this.dates,
    required this.marketPrices,
    required this.bsmiPrices,
    required this.minY,
    required this.maxY,
  });

  const ChartComparedSeriesResult.empty()
    : marketIndex = const [],
      bsmiIndex = const [],
      dates = const [],
      marketPrices = const [],
      bsmiPrices = const [],
      minY = 90,
      maxY = 110;

  final List<double> marketIndex;
  final List<double> bsmiIndex;
  final List<String> dates;
  final List<double> marketPrices;
  final List<double> bsmiPrices;
  final double minY;
  final double maxY;

  bool get isEmpty => marketIndex.isEmpty;
}
