import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/collection_value_calculator.dart';
import '../../data/models/collection_item_display.dart';
import '../../data/models/collection_item_model.dart';
import '../../data/repositories/collection_repository.dart';

class HomeController extends GetxController {
  final hasCollection = false.obs;

  final collectionValueText = r'$ —'.obs;
  final movedText = 'Moved — in last 3 months'.obs;

  final totalCollectionCount = 0.obs;

  /// Up to 10 collection bottles with highest `price_movement` (from `collection/all`).
  final topMovedBottles = <CollectionItemModel>[].obs;

  /// Chart series (last 9 points) in "k" units for display — market value.
  final chartSeriesK = <double>[].obs;
  /// BSMI / secondary series in "k" units (API `bsmi` or smoothed from price).
  final chartBsmiSeriesK = <double>[].obs;
  final chartMaxYk = 15.0.obs;

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
      topMovedBottles.assignAll(_pickTopMovedByPriceMovement(fetched));

      final formatter = NumberFormat.currency(
        locale: 'en_US',
        symbol: r'$',
        decimalDigits: 0,
      );

      final localTotal =
          CollectionValueCalculator.totalInvestedFromItems(fetched);

      final chart = await _repo.fetchChartData(
        lookBackDays: 90,
        forceRefresh: forceRefresh,
      );
      if (chart != null) {
        final series = chart['data'];
        if (series is List && series.isNotEmpty) {
          final points = <Map<String, dynamic>>[];
          for (final item in series) {
            if (item is Map && item['price'] != null) {
              final p = double.tryParse(item['price'].toString());
              if (p != null) {
                points.add(Map<String, dynamic>.from(item));
              }
            }
          }
          if (points.isNotEmpty) {
            final lastPoints = points.length > 9
                ? points.sublist(points.length - 9)
                : points;
            final prices = lastPoints
                .map((e) => double.parse(e['price'].toString()))
                .toList();
            final k = prices.map((e) => e / 1000.0).toList();
            chartSeriesK.assignAll(k);

            final bsmiFromApi = <double>[];
            var allHaveBsmi = true;
            for (final e in lastPoints) {
              final raw = e['bsmi'] ?? e['BSMI'] ?? e['secondary'];
              final v = double.tryParse(raw?.toString() ?? '');
              if (v == null) {
                allHaveBsmi = false;
                break;
              }
              bsmiFromApi.add(v / 1000.0);
            }
            if (allHaveBsmi && bsmiFromApi.length == k.length) {
              chartBsmiSeriesK.assignAll(bsmiFromApi);
            } else {
              chartBsmiSeriesK.assignAll(_smoothSeriesK(k));
            }

            final maxMain = k.reduce((a, b) => a > b ? a : b);
            final maxBsmi = chartBsmiSeriesK.isEmpty
                ? maxMain
                : chartBsmiSeriesK.reduce((a, b) => a > b ? a : b);
            final maxK = math.max(maxMain, maxBsmi);
            final rounded = ((maxK / 5).ceil() * 5).toDouble();
            chartMaxYk.value = rounded < 15 ? 15 : rounded;
          } else {
            chartSeriesK.clear();
            chartBsmiSeriesK.clear();
          }
        } else {
          chartSeriesK.clear();
          chartBsmiSeriesK.clear();
        }

        final first = double.tryParse(chart['first_price']?.toString() ?? '');
        final last = double.tryParse(chart['last_price']?.toString() ?? '');
        // Same rule as [CollectionController]: actual rows first; chart is fallback only.
        if (localTotal > 0) {
          collectionValueText.value = formatter.format(localTotal);
        } else if (last != null && last > 0) {
          collectionValueText.value = formatter.format(last);
        }
        if (first != null && last != null && first != 0) {
          final percent = ((last - first) / first) * 100;
          movedText.value =
              'Moved ${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(0)}% in last 3 months';
        } else {
          final index = chart['index'];
          final movement = (index is Map)
              ? double.tryParse(index['movement']?.toString() ?? '')
              : null;
          final trend = (index is Map)
              ? index['trend']?.toString().toLowerCase()
              : null;
          if (movement != null) {
            final sign = trend == 'down'
                ? '-'
                : trend == 'up'
                ? '+'
                : movement < 0
                ? ''
                : '+';
            movedText.value =
                'Moved $sign${movement.toStringAsFixed(1)}% in last 3 months';
          } else {
            movedText.value = 'Moved — in last 3 months';
          }
        }
      } else {
        chartSeriesK.clear();
        chartBsmiSeriesK.clear();
        _applyFallbackValue(fetched, formatter);
      }
    } catch (_) {
      topMovedBottles.clear();
      chartSeriesK.clear();
      chartBsmiSeriesK.clear();
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
    chartSeriesK.clear();
    chartBsmiSeriesK.clear();
    final total = CollectionValueCalculator.totalInvestedFromItems(list);
    if (total > 0) {
      collectionValueText.value = formatter.format(total);
    }
    movedText.value = 'Moved — in last 3 months';
  }

  Future<void> forceReload() => fetchHomeData(forceRefresh: true);
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

