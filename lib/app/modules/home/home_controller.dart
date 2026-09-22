import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/firebase/firebase_notification_topics.dart';
import '../../data/chart_index_comparison.dart';
import '../../data/collection_value_calculator.dart';
import '../../data/models/collection_item_display.dart';
import '../../data/models/collection_item_model.dart';
import '../../data/repositories/collection_repository.dart';
import '../session/user_session_controller.dart';

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

  /// Max points to plot for this filter (was hard-coded to 9 for all ranges).
  int get chartPointLimit => lookBackDays;

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

  /// Movement % from chart `first_price` / `last_price`; null → left bar at 0%.
  final collectionMovedPercent = Rxn<double>();

  final totalCollectionCount = 0.obs;
  final totalDrunkCount = 0.obs;
  final totalRareCount = 0.obs;

  /// From `collection/chart-data` → `collection_rating_percentage`.
  final collectionRatingText = '—'.obs;

  /// Up to 10 collection bottles with highest `price_movement` (from `collection/all`).
  final topMovedBottles = <CollectionItemModel>[].obs;

  /// Market value line — index-style (first point in window = 100).
  final chartSeriesK = <double>[].obs;
  /// BSMI line — same rebasing (`index_data` aligned to market dates).
  final chartBsmiSeriesK = <double>[].obs;
  /// Raw prices + dates for chart touch tooltips (aligned to [chartSeriesK]).
  final chartPointDates = <String>[].obs;
  final chartMarketPrices = <double>[].obs;
  final chartBsmiPrices = <double>[].obs;
  final chartMinY = 90.0.obs;
  final chartMaxYk = 110.0.obs;
  final selectedChartRange = HomeChartRange.m3.obs;
  final chartLoading = false.obs;
  /// Bumps when chart series reload so [LineChart] rebuilds on filter change.
  final chartRevision = 0.obs;

  final isLoading = false.obs;

  final _repo = Get.find<CollectionRepository>();

  @override
  void onInit() {
    super.onInit();
    fetchHomeData();
  }

  Future<void> _syncNotificationTopics() async {
    if (Get.isRegistered<UserSessionController>()) {
      final user = Get.find<UserSessionController>().user.value;
      await FirebaseNotificationTopics.syncUserTierTopic(user);
    }
  }

  Future<void> fetchHomeData({bool forceRefresh = false}) async {
    unawaited(_syncNotificationTopics());
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
    collectionMovedPercent.value = null;
  }

  /// Default Y range when API returns no chart points (index scale).
  static const double emptyChartMinY = 90;
  static const double emptyChartMaxYk = 110;

  void _clearChartSeries() {
    chartSeriesK.clear();
    chartBsmiSeriesK.clear();
    chartPointDates.clear();
    chartMarketPrices.clear();
    chartBsmiPrices.clear();
    chartMinY.value = emptyChartMinY;
    chartMaxYk.value = emptyChartMaxYk;
    collectionMovedPercent.value = null;
  }

  void _applyMovedForRange({
    required double? percent,
    required String period,
  }) {
    collectionMovedPercent.value = percent;
    if (!hasCollection.value) {
      movedText.value = 'Moved — in $period';
    } else if (percent != null) {
      movedText.value =
          'Moved ${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(2)}% in $period';
    } else {
      movedText.value = 'Moved — in $period';
    }
  }

  Future<void> setChartRange(HomeChartRange range) async {
    if (selectedChartRange.value == range) return;
    selectedChartRange.value = range;
    chartLoading.value = true;
    try {
      final formatter = NumberFormat.currency(
        locale: 'en_US',
        symbol: r'$',
        decimalDigits: 0,
      );
      await _loadChart(formatter: formatter, forceRefresh: true);
    } finally {
      chartLoading.value = false;
    }
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
      _applyMovedForRange(percent: null, period: range.movedPeriodLabel);
      return;
    }

    _applyChartQuickStats(chart);

    final marketPoints = ChartIndexComparison.parsePriceSeries(chart['data']);
    if (marketPoints.isNotEmpty) {
      final indexPoints =
          ChartIndexComparison.parsePriceSeries(chart['index_data']);
      final compared = ChartIndexComparison.buildComparedSeries(
        marketPoints: marketPoints,
        indexPoints: indexPoints,
        maxPoints: range.chartPointLimit,
      );
      chartSeriesK.assignAll(compared.marketIndex);
      chartBsmiSeriesK.assignAll(compared.bsmiIndex);
      chartPointDates.assignAll(compared.dates);
      chartMarketPrices.assignAll(compared.marketPrices);
      chartBsmiPrices.assignAll(compared.bsmiPrices);
      chartMinY.value = compared.minY;
      chartMaxYk.value = compared.maxY;
      chartRevision.value++;
    } else {
      _clearChartSeries();
    }

    final first = double.tryParse(chart['first_price']?.toString() ?? '');
    final last = double.tryParse(chart['last_price']?.toString() ?? '');
    final period = range.movedPeriodLabel;
    final percent = CollectionValueCalculator.movedPercentFromFirstLast(
      first: first,
      last: last,
    );
    _applyMovedForRange(percent: percent, period: period);
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

