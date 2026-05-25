import 'dart:math' as math;

/// Index-style chart comparison (bourboneur `chart_page/chart.dart`).
///
/// Each series is rebased so its first point in the window = 100, then
/// `(price / firstPrice) * 100`, so Market Value and BSMI can be compared
/// on one axis as relative performance, not raw dollars.
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

  /// Align `index_data` prices to market-value dates; carry forward last known.
  static List<Map<String, dynamic>> alignIndexToMarketDates({
    required List<Map<String, dynamic>> marketPoints,
    required List<Map<String, dynamic>> indexPoints,
  }) {
    if (marketPoints.isEmpty || indexPoints.isEmpty) return [];

    final indexByDate = <String, double>{};
    for (final p in indexPoints) {
      final date = p['date']?.toString();
      if (date == null || date.isEmpty) continue;
      final price = double.tryParse(p['price']?.toString() ?? '');
      if (price != null) indexByDate[date] = price;
    }

    final aligned = <Map<String, dynamic>>[];
    double? lastPrice;
    for (final m in marketPoints) {
      final date = m['date']?.toString() ?? '';
      if (indexByDate.containsKey(date)) {
        lastPrice = indexByDate[date];
      }
      if (lastPrice == null) continue;
      aligned.add({'date': date, 'price': lastPrice.toString()});
    }

    return aligned.length == marketPoints.length ? aligned : [];
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
      bsmiPrices: bsmiWindow.isEmpty ? <double>[] : _pricesFromPoints(bsmiWindow),
      minY: bounds.$1,
      maxY: bounds.$2,
    );
  }

  static (double, double) _indexAxisBounds(List<double> values) {
    if (values.isEmpty) return (90, 110);
    var minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    var span = maxV - minV;
    if (span < 1) {
      minV = 95;
      maxV = 105;
      span = 10;
    }
    final pad = span * 0.12;
    return (math.max(0, minV - pad), maxV + pad);
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
