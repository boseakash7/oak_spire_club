import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/collection_value_calculator.dart';
import '../../data/models/collection_item_display.dart';
import '../../data/models/collection_item_model.dart';
import '../../data/repositories/collection_repository.dart';

/// Collection value chart lookback (Figma home — 1M / 3M / 6M / 1Y chips).
enum HomeChartRange {
  m1,
  m3,
  m6,
  y1;

  String get label => switch (this) {
        HomeChartRange.m1 => '1M',
        HomeChartRange.m3 => '3M',
        HomeChartRange.m6 => '6M',
        HomeChartRange.y1 => '1Y',
      };

  int get lookBackDays => switch (this) {
        HomeChartRange.m1 => 30,
        HomeChartRange.m3 => 90,
        HomeChartRange.m6 => 182,
        HomeChartRange.y1 => 365,
      };

  String get movedPeriodLabel => switch (this) {
        HomeChartRange.m1 => 'last month',
        HomeChartRange.m3 => 'last 3 months',
        HomeChartRange.m6 => 'last 6 months',
        HomeChartRange.y1 => 'last year',
      };
}

class HomeController extends GetxController {
  final hasCollection = false.obs;

  final collectionValueText = r'$ —'.obs;
  final movedText = 'Moved — in last 3 months'.obs;

  final totalCollectionCount = 0.obs;
  final totalDrunkCount = 0.obs;
  final totalRareCount = 0.obs;

  /// From `collection/chart-data` → `collection_rating_percentage`.
  final collectionRatingText = '—'.obs;

  /// Up to 10 collection bottles with highest `price_movement` (from `collection/all`).
  final topMovedBottles = <CollectionItemModel>[].obs;

  /// Chart series (last 9 points) in "k" units for display — market value (`data`).
  final chartSeriesK = <double>[].obs;
  /// BSMI series in "k" units (`index_data`, or legacy per-point / smoothed fallback).
  final chartBsmiSeriesK = <double>[].obs;
  final chartMaxYk = 15.0.obs;
  final selectedChartRange = HomeChartRange.m3.obs;

  final isLoading = false.obs;

  final _repo = Get.find<CollectionRepository>();

  @override
  void onInit() {
    super.onInit();
    fetchHomeData();
  }

  Future<void> fetchHomeData({bool forceRefresh = false}) async {
    isLoading.value = true;
    final list = <CollectionItemModel>[];
    try {
      final fetched = await _repo.fetchMyCollection(forceRefresh: forceRefresh);
      list
        ..clear()
        ..addAll(fetched);
      hasCollection.value = fetched.isNotEmpty;
      totalCollectionCount.value = fetched.length;
      totalDrunkCount.value = fetched.where((item) => item.isDrunk).length;
      totalRareCount.value = fetched.where((item) => item.isRareFind).length;
      topMovedBottles.assignAll(_pickTopMovedByPriceMovement(fetched));

      final formatter = NumberFormat.currency(
        locale: 'en_US',
        symbol: r'$',
        decimalDigits: 0,
      );

      final localTotal =
          CollectionValueCalculator.totalInvestedFromItems(fetched);

      if (localTotal > 0) {
        collectionValueText.value = formatter.format(localTotal);
      } else {
        collectionValueText.value = r'$ —';
      }

      await _loadChart(formatter: formatter, forceRefresh: forceRefresh);
    } catch (_) {
      topMovedBottles.clear();
      totalDrunkCount.value = list.where((item) => item.isDrunk).length;
      totalRareCount.value = list.where((item) => item.isRareFind).length;
      _clearChartSeries();
      _applyFallbackValue(
        list,
        NumberFormat.currency(
          locale: 'en_US',
          symbol: r'$',
          decimalDigits: 0,
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Highest [price_movement] first; one row per bluebook bottle; max [limit].
  static List<CollectionItemModel> _pickTopMovedByPriceMovement(
    Iterable<CollectionItemModel> items, {
    int limit = 10,
  }) {
    final ranked = <({CollectionItemModel item, double movement})>[];
    for (final item in items) {
      final movement = item.priceMovementValue;
      if (movement == null) continue;
      ranked.add((item: item, movement: movement));
    }
    ranked.sort((a, b) => b.movement.compareTo(a.movement));

    final seenBottleIds = <String>{};
    final out = <CollectionItemModel>[];
    for (final row in ranked) {
      final dedupeKey = row.item.bluebookBottleId ?? row.item.id;
      if (!seenBottleIds.add(dedupeKey)) continue;
      out.add(row.item);
      if (out.length >= limit) break;
    }
    return out;
  }

  void _applyFallbackValue(
    Iterable<CollectionItemModel> list,
    NumberFormat formatter,
  ) {
    topMovedBottles.assignAll(_pickTopMovedByPriceMovement(list));
    totalDrunkCount.value = list.where((item) => item.isDrunk).length;
    totalRareCount.value = list.where((item) => item.isRareFind).length;
    _clearChartSeries();
    final total = CollectionValueCalculator.totalInvestedFromItems(list);
    collectionValueText.value =
        total > 0 ? formatter.format(total) : r'$ —';
    movedText.value = 'Moved — in last 3 months';
  }

  /// Y-axis max when API returns no chart points (grid only, no lines).
  static const double emptyChartMaxYk = 15;

  void _clearChartSeries() {
    chartSeriesK.clear();
    chartBsmiSeriesK.clear();
    chartMaxYk.value = emptyChartMaxYk;
  }

  Future<void> setChartRange(HomeChartRange range) async {
    if (selectedChartRange.value == range) return;
    selectedChartRange.value = range;
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: r'$',
      decimalDigits: 0,
    );
    await _loadChart(formatter: formatter, forceRefresh: true);
  }

  Future<void> _loadChart({
    required NumberFormat formatter,
    required bool forceRefresh,
  }) async {
    final range = selectedChartRange.value;
    final chart = await _repo.fetchChartData(
      lookBackDays: range.lookBackDays,
      forceRefresh: forceRefresh,
    );
    if (chart == null) {
      _clearChartSeries();
      if (!hasCollection.value) {
        movedText.value = 'Moved — in ${range.movedPeriodLabel}';
      }
      return;
    }

    _applyChartQuickStats(chart);

    final marketPoints = _parseChartPriceSeries(chart['data']);
    if (marketPoints.isNotEmpty) {
      final lastMarket = _lastChartPoints(marketPoints);
      final k = _pricesToK(lastMarket);
      chartSeriesK.assignAll(k);

      final indexPoints = _parseChartPriceSeries(chart['index_data']);
      final bsmiK = _bsmiSeriesK(
        marketPoints: lastMarket,
        indexPoints: indexPoints,
      );
      if (bsmiK != null && bsmiK.length == k.length) {
        chartBsmiSeriesK.assignAll(bsmiK);
      } else {
        chartBsmiSeriesK.assignAll(_smoothSeriesK(k));
      }

      final maxMain = k.reduce((a, b) => a > b ? a : b);
      final maxBsmi = chartBsmiSeriesK.isEmpty
          ? maxMain
          : chartBsmiSeriesK.reduce((a, b) => a > b ? a : b);
      final maxK = math.max(maxMain, maxBsmi);
      chartMaxYk.value = niceChartMaxK(maxK);
    } else {
      _clearChartSeries();
    }

    final first = double.tryParse(chart['first_price']?.toString() ?? '');
    final last = double.tryParse(chart['last_price']?.toString() ?? '');
    final period = range.movedPeriodLabel;
    if (!hasCollection.value) {
      movedText.value = 'Moved — in $period';
    } else if (first != null && last != null && last != 0) {
      final percent = CollectionValueCalculator.movedPercentFromFirstLast(
        first: first,
        last: last,
      )!;
      movedText.value =
          'Moved ${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(2)}% in $period';
    } else {
      final index = chart['index'];
      final movement = (index is Map)
          ? double.tryParse(index['movement']?.toString() ?? '')
          : null;
      final trend =
          (index is Map) ? index['trend']?.toString().toLowerCase() : null;
      if (movement != null) {
        final sign = trend == 'down'
            ? '-'
            : trend == 'up'
            ? '+'
            : movement < 0
            ? ''
            : '+';
        movedText.value =
            'Moved $sign${movement.toStringAsFixed(1)}% in $period';
      } else {
        movedText.value = 'Moved — in $period';
      }
    }
  }

  Future<void> forceReload() => fetchHomeData(forceRefresh: true);

  void _applyChartQuickStats(Map<String, dynamic> chart) {
    final rareRaw = chart['rare_bottles_count'];
    if (rareRaw != null) {
      final rare = int.tryParse(rareRaw.toString());
      if (rare != null) totalRareCount.value = rare;
    }

    collectionRatingText.value = _formatCollectionRating(
      chart['collection_rating_percentage'],
    );
  }

  /// `collection_rating_percentage` is 0–100; Quick Stats shows a 0–5 value with star.
  static String _formatCollectionRating(dynamic raw) {
    final v = double.tryParse(raw?.toString() ?? '');
    if (v == null) return '—';

    final double onFiveScale;
    if (v <= 5) {
      onFiveScale = v;
    } else {
      onFiveScale = (v / 100) * 5;
    }

    if (onFiveScale == onFiveScale.roundToDouble()) {
      return onFiveScale.toInt().toString();
    }
    return onFiveScale.toStringAsFixed(1);
  }
}

const int _kChartPointLimit = 9;

List<Map<String, dynamic>> _parseChartPriceSeries(dynamic raw) {
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

List<Map<String, dynamic>> _lastChartPoints(
  List<Map<String, dynamic>> points, {
  int maxPoints = _kChartPointLimit,
}) {
  if (points.length <= maxPoints) return points;
  return points.sublist(points.length - maxPoints);
}

List<double> _pricesToK(List<Map<String, dynamic>> points) {
  return points
      .map((e) => double.parse(e['price'].toString()) / 1000.0)
      .toList();
}

/// BSMI from `index_data`, aligned to market-value dates when possible.
List<double>? _bsmiSeriesK({
  required List<Map<String, dynamic>> marketPoints,
  required List<Map<String, dynamic>> indexPoints,
}) {
  if (indexPoints.isNotEmpty) {
    final indexByDate = <String, double>{};
    for (final p in indexPoints) {
      final date = p['date']?.toString();
      if (date == null || date.isEmpty) continue;
      final price = double.tryParse(p['price']?.toString() ?? '');
      if (price != null) indexByDate[date] = price;
    }

    final byDate = <double>[];
    for (final m in marketPoints) {
      final date = m['date']?.toString();
      final price = date != null ? indexByDate[date] : null;
      if (price == null) break;
      byDate.add(price / 1000.0);
    }
    if (byDate.length == marketPoints.length) return byDate;

    final n = marketPoints.length;
    final positional = indexPoints.length > n
        ? indexPoints.sublist(indexPoints.length - n)
        : indexPoints;
    if (positional.length == n) return _pricesToK(positional);
  }

  final embedded = <double>[];
  var allHaveEmbedded = true;
  for (final e in marketPoints) {
    final raw = e['bsmi'] ?? e['BSMI'] ?? e['secondary'];
    final v = double.tryParse(raw?.toString() ?? '');
    if (v == null) {
      allHaveEmbedded = false;
      break;
    }
    embedded.add(v / 1000.0);
  }
  if (allHaveEmbedded && embedded.length == marketPoints.length) {
    return embedded;
  }

  return null;
}

/// Rounds up to a readable Y-axis max (e.g. 1.0 → 2, 12 → 15).
double niceChartMaxK(double maxValueK) {
  if (maxValueK <= 0) return 1;
  final padded = maxValueK * 1.1;
  if (padded <= 1) return 1;

  final exp = (math.log(padded) / math.ln10).floor();
  final magnitude = math.pow(10, exp).toDouble();
  final fraction = padded / magnitude;

  final double niceFraction;
  if (fraction <= 1) {
    niceFraction = 1;
  } else if (fraction <= 2) {
    niceFraction = 2;
  } else if (fraction <= 5) {
    niceFraction = 5;
  } else {
    niceFraction = 10;
  }

  return niceFraction * magnitude;
}

/// 3-point moving average for a BSMI-style smoother from the same price series.
List<double> _smoothSeriesK(List<double> k) {
  if (k.isEmpty) return [];
  if (k.length == 1) return [k.first];
  return List<double>.generate(k.length, (i) {
    final i0 = (i - 1).clamp(0, k.length - 1);
    final i2 = (i + 1).clamp(0, k.length - 1);
    return (k[i0] + k[i] + k[i2]) / 3.0;
  });
}

