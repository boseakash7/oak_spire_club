import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/firebase/firebase_notification_topics.dart';
import '../../core/utils/rating_formatter.dart';
import '../../data/chart_index_comparison.dart';
import '../../data/collection_value_calculator.dart';
import '../../data/models/collection_item_display.dart';
import '../../data/models/collection_item_model.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/market_repository.dart';
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

  /// The `market/index-detail` window covering this range (30 / 90 / 180 /
  /// 365; 6M asks for 180).
  int get indexDays => switch (this) {
    HomeChartRange.m1 => 30,
    HomeChartRange.m3 => 90,
    HomeChartRange.m6 => 180,
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

  /// Hero figure — what the collection is worth today (bluebook average ×
  /// quantity). Falls back to invested value when no row carries a market
  /// price, in which case [showingInvestedAsValue] is true.
  final collectionValueText = r'$ —'.obs;

  /// Raw hero value, for the count-up animation.
  final collectionValue = 0.0.obs;

  /// True when the hero number is cost basis rather than market value, so the
  /// UI can label it honestly instead of calling spend "value".
  final showingInvestedAsValue = false.obs;

  /// Cost basis — what the user paid in total.
  final investedValueText = r'$ —'.obs;

  /// Market value minus invested; null when either side is unknown.
  final unrealisedGain = Rxn<double>();
  final unrealisedGainText = ''.obs;

  final movedText = 'Moved — in last 3 months'.obs;

  /// Movement % from chart `first_price` / `last_price`; null → left bar at 0%.
  final collectionMovedPercent = Rxn<double>();

  /// Collection rows (one per bottle, duplicates merged).
  final totalCollectionCount = 0.obs;
  final totalDrunkCount = 0.obs;
  final totalRareCount = 0.obs;

  /// Physical bottles (quantities summed), and how many of them are opened
  /// or still sealed.
  final totalBottleCount = 0.obs;
  final openedBottleCount = 0.obs;
  final sealedBottleCount = 0.obs;

  /// The collection as `collection/all` returned it, grouped. Home ranks
  /// these by their 90-day price lines.
  final items = <CollectionItemModel>[].obs;

  /// From `collection/chart-data` → `collection_rating_percentage`.
  final collectionRatingText = '—'.obs;

  /// Market value line — index-style (first point in window = 100).
  final chartSeriesK = <double>[].obs;

  /// The Oak Spire Index line, same rebasing (its daily values, as of each
  /// market date). Empty when the index can't be loaded.
  final chartIndexSeriesK = <double>[].obs;

  /// The compared index's name, for the legend and tooltip.
  final chartIndexName = 'Oak Spire Index'.obs;

  /// Raw prices + dates for chart touch tooltips (aligned to [chartSeriesK]).
  final chartPointDates = <String>[].obs;
  final chartMarketPrices = <double>[].obs;
  final chartIndexPrices = <double>[].obs;
  final chartMinY = 90.0.obs;
  final chartMaxYk = 110.0.obs;
  final selectedChartRange = HomeChartRange.m3.obs;
  final chartLoading = false.obs;

  /// Bumps when chart series reload so [LineChart] rebuilds on filter change.
  final chartRevision = 0.obs;

  /// The header's second line: the collection's move today, or this week
  /// when today was flat, e.g. `▲ $124 today`. Empty when there is nothing
  /// to say (no collection, no chart data).
  final headerMoveText = ''.obs;

  /// Sign of [headerMoveText] for its color; null when flat or empty.
  final headerMoveUp = RxnBool();

  final isLoading = false.obs;

  final _repo = Get.find<CollectionRepository>();
  final _marketRepo = Get.find<MarketRepository>();

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

  /// [background] keeps the current screen on-screen while refetching. Used
  /// when returning to the Home tab, where flashing the skeleton over content
  /// the user was just looking at reads as a glitch.
  Future<void> fetchHomeData({
    bool forceRefresh = false,
    bool background = false,
  }) async {
    unawaited(_syncNotificationTopics());
    final showSkeleton = !background || !hasCollection.value;
    if (showSkeleton) isLoading.value = true;
    final list = <CollectionItemModel>[];
    try {
      final fetched = await _repo.fetchMyCollection(forceRefresh: forceRefresh);
      list
        ..clear()
        ..addAll(fetched);
      hasCollection.value = fetched.isNotEmpty;
      _applyCounts(fetched);

      final formatter = NumberFormat.currency(
        locale: 'en_US',
        symbol: r'$',
        decimalDigits: 0,
      );

      _applyValueFigures(fetched, formatter);

      await _loadChart(formatter: formatter, forceRefresh: forceRefresh);
    } catch (_) {
      _clearChartSeries();
      // A failed fetch (list still empty) keeps the last figures and counts
      // rather than zeroing a collection that is still there.
      if (list.isNotEmpty) {
        _applyFallbackValue(
          list,
          NumberFormat.currency(
            locale: 'en_US',
            symbol: r'$',
            decimalDigits: 0,
          ),
        );
      }
    } finally {
      if (showSkeleton) isLoading.value = false;
    }
  }

  void _applyCounts(Iterable<CollectionItemModel> list) {
    var bottles = 0;
    var opened = 0;
    for (final item in list) {
      bottles += item.displayQuantity;
      opened += item.openedBottleCount;
    }
    totalCollectionCount.value = list.length;
    totalBottleCount.value = bottles;
    openedBottleCount.value = opened;
    sealedBottleCount.value = bottles - opened;
    totalDrunkCount.value = list.where((item) => item.isDrunk).length;
    totalRareCount.value = list.where((item) => item.isRareFind).length;
    items.assignAll(list);
  }

  /// Sets the hero value, the invested line and the unrealised gain from
  /// [CollectionValueCalculator.summarize], the same figures Collection shows.
  ///
  /// Market value leads because that is what the app is for; invested value is
  /// the supporting figure. When no row has a bluebook price there is no market
  /// value to show, so invested takes the hero slot and is labelled as such.
  void _applyValueFigures(
    Iterable<CollectionItemModel> items,
    NumberFormat formatter,
  ) {
    final summary = CollectionValueCalculator.summarize(items);

    investedValueText.value = summary.invested > 0
        ? formatter.format(summary.invested)
        : r'$ —';

    showingInvestedAsValue.value = summary.showingInvestedAsValue;
    collectionValue.value = summary.value;
    collectionValueText.value = summary.value > 0
        ? formatter.format(summary.value)
        : r'$ —';

    final gain = summary.gain;
    unrealisedGain.value = gain;
    unrealisedGainText.value = gain == null
        ? ''
        : '${gain >= 0 ? '+' : '-'}${formatter.format(gain.abs())}';
  }

  void _applyFallbackValue(
    Iterable<CollectionItemModel> list,
    NumberFormat formatter,
  ) {
    _applyCounts(list);
    _clearChartSeries();
    _applyValueFigures(list, formatter);
    movedText.value = 'Moved — in last 3 months';
    collectionMovedPercent.value = null;
  }

  /// Default Y range when API returns no chart points (index scale).
  static const double emptyChartMinY = 90;
  static const double emptyChartMaxYk = 110;

  void _clearChartSeries() {
    headerMoveText.value = '';
    headerMoveUp.value = null;
    chartSeriesK.clear();
    chartIndexSeriesK.clear();
    chartPointDates.clear();
    chartMarketPrices.clear();
    chartIndexPrices.clear();
    chartMinY.value = emptyChartMinY;
    chartMaxYk.value = emptyChartMaxYk;
    collectionMovedPercent.value = null;
  }

  void _applyMovedForRange({required double? percent, required String period}) {
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
    final (chart, indexPoints) = await (
      _repo.fetchChartData(
        lookBackDays: range.lookBackDays,
        forceRefresh: forceRefresh,
      ),
      _loadIndexPoints(range, forceRefresh: forceRefresh),
    ).wait;
    if (chart == null) {
      _clearChartSeries();
      _applyMovedForRange(percent: null, period: range.movedPeriodLabel);
      return;
    }

    _applyChartQuickStats(chart);

    final marketPoints = ChartIndexComparison.parsePriceSeries(chart['data']);
    _applyHeaderMove(marketPoints, formatter);
    if (marketPoints.isNotEmpty) {
      final compared = ChartIndexComparison.buildComparedSeries(
        marketPoints: marketPoints,
        indexPoints: indexPoints,
        maxPoints: range.chartPointLimit,
      );
      chartSeriesK.assignAll(compared.marketIndex);
      chartIndexSeriesK.assignAll(compared.bsmiIndex);
      chartPointDates.assignAll(compared.dates);
      chartMarketPrices.assignAll(compared.marketPrices);
      chartIndexPrices.assignAll(compared.bsmiPrices);
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

  /// The headline Oak Spire Index over [range], as `{date, price}` points.
  /// Optional like every market part: on failure the chart shows the
  /// collection alone.
  Future<List<Map<String, dynamic>>> _loadIndexPoints(
    HomeChartRange range, {
    required bool forceRefresh,
  }) async {
    try {
      final indexes = await _marketRepo.indexes(forceRefresh: forceRefresh);
      final headline =
          indexes.where((i) => i.isHeadline).firstOrNull ?? indexes.firstOrNull;
      final detail = await _marketRepo.indexDetail(
        slug: headline?.slug ?? 'market',
        days: range.indexDays,
        forceRefresh: forceRefresh,
      );
      final index = detail.index;
      if (index == null) return const [];
      chartIndexName.value = index.name;
      final day = DateFormat('yyyy-MM-dd');
      return [
        for (final p in index.series)
          {'date': day.format(p.date), 'price': p.value},
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Today's change from the daily value series, falling back to the last
  /// seven days when today was flat. Every chart range covers both.
  void _applyHeaderMove(
    List<Map<String, dynamic>> points,
    NumberFormat formatter,
  ) {
    final prices = [
      for (final p
          in [...points]..sort(
            (a, b) => (a['date']?.toString() ?? '').compareTo(
              b['date']?.toString() ?? '',
            ),
          ))
        double.parse(p['price'].toString()),
    ];
    if (!hasCollection.value || prices.length < 2) {
      headerMoveText.value = '';
      headerMoveUp.value = null;
      return;
    }

    final last = prices.last;
    var change = last - prices[prices.length - 2];
    var period = 'today';
    if (change.abs() < 0.5) {
      change = last - prices[prices.length > 7 ? prices.length - 8 : 0];
      period = 'this week';
    }
    if (change.abs() < 0.5) {
      headerMoveText.value = 'Steady this week';
      headerMoveUp.value = null;
      return;
    }
    headerMoveUp.value = change > 0;
    headerMoveText.value =
        '${change > 0 ? '▲' : '▼'} ${formatter.format(change.abs())} $period';
  }

  /// Pull-to-refresh and "added a bottle": refetch while the current content
  /// stays on screen (the skeleton only shows when there is nothing yet).
  Future<void> forceReload() =>
      fetchHomeData(forceRefresh: true, background: true);

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

  /// `collection_rating_percentage` is the average bottle rating, out of 100
  /// like `bluebook.rating`; Quick Stats shows it out of 10.
  static String _formatCollectionRating(dynamic raw) =>
      RatingFormatter.label(raw);
}
