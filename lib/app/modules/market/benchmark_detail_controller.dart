import 'dart:async';

import 'package:get/get.dart';

import '../../core/storage/app_storage.dart';
import '../../core/utils/app_image_url.dart';
import '../../core/utils/greeting_formatter.dart';
import '../../core/utils/price_formatter.dart';
import '../../core/utils/proof_formatter.dart';
import '../../core/utils/rating_formatter.dart';
import '../session/user_session_controller.dart';
import '../../data/deal_check.dart';
import '../../data/models/bluebook_model.dart';
import '../../data/models/bluebook_price_history_chart_model.dart';
import '../../data/models/bottle_details.dart';
import '../../data/models/bottle_pricing.dart';
import '../../data/models/collection_item_display.dart';
import '../../data/models/collection_item_model.dart';
import '../../data/repositories/bluebook_price_history_repository.dart';
import '../../data/repositories/bluebook_repository.dart';
import '../../data/repositories/collection_repository.dart';
import '../add_collection/add_to_collection_launcher.dart';

/// Payload passed via [Get.toNamed] / route `arguments` for benchmark bottle detail.
class BenchmarkDetailRouteArgs {
  const BenchmarkDetailRouteArgs({
    this.bottleId,
    required this.name,
    this.imagePathOrUrl,
    this.averageRaw,
    this.lowRaw,
    this.highRaw,
    this.proof,
    this.description,
    this.rating,
    this.priceMovement,
  });

  factory BenchmarkDetailRouteArgs.from(dynamic arguments) {
    final Map<String, dynamic> map;
    if (arguments is Map) {
      map = Map<String, dynamic>.from(arguments);
    } else {
      map = {};
    }
    return BenchmarkDetailRouteArgs(
      bottleId: map['id']?.toString(),
      name: (map['name'] ?? _kDefaultName).toString(),
      imagePathOrUrl: map['image']?.toString(),
      averageRaw: map['average']?.toString(),
      lowRaw: map['low']?.toString(),
      highRaw: map['high']?.toString(),
      proof: map['proof']?.toString(),
      description: map['description']?.toString(),
      rating: map['rating']?.toString(),
      priceMovement: map['price_movement']?.toString(),
    );
  }

  /// The route arguments for a catalog bottle, as every market list sends
  /// them (rows, movers, Home strips).
  static Map<String, dynamic> mapFromBluebook(BluebookModel bottle) => {
    'id': bottle.id,
    'name': bottle.bottleName,
    'image': bottle.image,
    'average': bottle.average,
    'low': bottle.low,
    'high': bottle.high,
    'proof': bottle.proof,
    'description': bottle.description,
    'rating': bottle.rating,
    'price_movement': bottle.priceMovement,
  };

  static const _kDefaultName = 'Batons single Barrel 10 Years multicusting';

  final String? bottleId;
  final String name;
  final String? imagePathOrUrl;
  final String? averageRaw;
  final String? lowRaw;
  final String? highRaw;
  final String? proof;
  final String? description;
  final String? rating;
  final String? priceMovement;
}

/// Price chart range for [bluebook-price-history/chart-data-dashboard].
enum BenchmarkDetailChartRange {
  m1,
  m3,
  m6,
  y1;

  String get label => switch (this) {
    BenchmarkDetailChartRange.m1 => '1M',
    BenchmarkDetailChartRange.m3 => '3M',
    BenchmarkDetailChartRange.m6 => '6M',
    BenchmarkDetailChartRange.y1 => '1Y',
  };

  int get _approxDays => switch (this) {
    BenchmarkDetailChartRange.m1 => 30,
    BenchmarkDetailChartRange.m3 => 90,
    BenchmarkDetailChartRange.m6 => 182,
    BenchmarkDetailChartRange.y1 => 365,
  };

  /// Inclusive calendar day for `endDate`; `fromDate` is `end` minus [_approxDays].
  (DateTime from, DateTime to) dateBoundsToToday() {
    final now = DateTime.now();
    final to = DateTime(now.year, now.month, now.day);
    final from = to.subtract(Duration(days: _approxDays));
    return (from, to);
  }
}

String _formatChartApiDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class BenchmarkDetailController extends GetxController {
  BenchmarkDetailController({
    required CollectionRepository collectionRepo,
    required BluebookPriceHistoryRepository priceHistoryRepo,
    required BluebookRepository bluebookRepo,
  }) : _collectionRepo = collectionRepo,
       _priceHistoryRepo = priceHistoryRepo,
       _bluebookRepo = bluebookRepo;

  final CollectionRepository _collectionRepo;
  final BluebookPriceHistoryRepository _priceHistoryRepo;
  final BluebookRepository _bluebookRepo;
  late final String? bottleId;
  late final String productName;
  late final String? rawAverage;
  late final String avgFormatted;
  late final String lowFormatted;
  late final String highFormatted;
  late final String? imageUrl;
  late final String? imagePathOrUrl;
  late final String? proofText;
  late final String? ratingDisplay;

  /// Numeric average / low / high from the route, for the deal check.
  late final double? averageValue;
  late final double? lowValue;
  late final double? highValue;

  /// What the user typed into the deal check; null when empty.
  final askingPrice = Rxn<double>();

  /// The asking price against the market; null until one is typed, or when
  /// the bottle has no average.
  DealCheck? get dealCheck => DealCheck.evaluate(
    asking: askingPrice.value,
    average: averageValue,
    low: lowValue,
    high: highValue,
  );

  /// From the route arguments, then topped up by [fetchDetails].
  final description = RxnString();

  /// Distillery, age, ABV and the rest of the catalog facts. Null until the
  /// by-id request answers; a failed request leaves it null, and the page
  /// simply has no facts section.
  final details = Rxn<BottleDetails>();
  final detailsLoading = false.obs;
  final isRare = false.obs;
  late final String? priceMovementRaw;

  final selectedChartRange = BenchmarkDetailChartRange.y1.obs;
  final chartLoading = false.obs;
  final chartError = RxnString();
  final chartPoints = <BluebookPriceChartPoint>[].obs;

  /// Y values for the BSMI line, same length as [chartPoints] — only when the
  /// API sends a per-point `bsmi`. Empty means "no benchmark to compare", and
  /// the chart hides that series rather than inventing one.
  final chartBsmiValues = <double>[].obs;

  /// What this bottle's price rests on (from the chart endpoint's bottle).
  final pricing = Rxn<BottlePricing>();

  /// Chart / legend name for the price line. An admin-entered price is an
  /// Oak Spire price, never "market value" (ai-features-plan.md §2.5).
  String get marketSeriesLabel => pricing.value?.isOakSpirePrice == true
      ? 'Oak Spire price'
      : 'Market Value';

  final collectionLoading = false.obs;
  final hasInCollection = false.obs;
  final collectionQuantity = 0.obs;
  final collectionFillRatio = 0.0.obs;
  final collectionPaidLabel = '—'.obs;
  final collectionPriceMovementRaw = RxnString();
  final collectionGainDollars = Rxn<double>();

  String get greetingText {
    if (Get.isRegistered<UserSessionController>()) {
      return Get.find<UserSessionController>().greetingText;
    }
    final stored = AppStorage.user;
    final name =
        stored?['name']?.toString() ?? stored?['first_name']?.toString();
    return GreetingFormatter.personalized(name, fallback: 'User');
  }

  @override
  void onInit() {
    super.onInit();
    final args = BenchmarkDetailRouteArgs.from(Get.arguments);
    bottleId = args.bottleId;
    productName = args.name;
    rawAverage = args.averageRaw;
    avgFormatted = PriceFormatter.format(args.averageRaw);
    lowFormatted = PriceFormatter.format(args.lowRaw);
    highFormatted = PriceFormatter.format(args.highRaw);
    averageValue = _money(args.averageRaw);
    lowValue = _money(args.lowRaw);
    highValue = _money(args.highRaw);
    imagePathOrUrl = args.imagePathOrUrl;
    imageUrl = AppImageUrl.resolve(args.imagePathOrUrl);
    proofText = ProofFormatter.formatLabel(_nullableRouteString(args.proof));
    description.value = _nullableRouteString(args.description);
    // Stored out of 100; shown out of 10 like everywhere else.
    ratingDisplay = RatingFormatter.outOfTen(args.rating) == null
        ? null
        : RatingFormatter.labelOutOfTen(args.rating);
    priceMovementRaw = _nullableRouteString(args.priceMovement);
    if (_canLoadPriceChart) {
      unawaited(fetchPriceChart());
      unawaited(fetchDetails());
    }
    unawaited(_loadCollectionOwnership());
  }

  /// Pull-to-refresh: re-pull the price chart, the catalog facts and this
  /// user's ownership rows.
  Future<void> reload() async {
    await Future.wait([
      if (_canLoadPriceChart) fetchPriceChart(),
      if (_canLoadPriceChart) fetchDetails(),
      _loadCollectionOwnership(),
    ]);
  }

  /// The route arguments carry only what the list row had. The by-id request
  /// brings the rest, whichever screen opened this one (market, collection,
  /// home).
  Future<void> fetchDetails() async {
    if (!_canLoadPriceChart) return;
    detailsLoading.value = true;
    try {
      final bottle = await _bluebookRepo.getById(bottleId!);
      details.value = bottle.details;
      isRare.value = bottle.isRare == true;
      final text = _nullableRouteString(bottle.description);
      if (text != null) description.value = text;
      pricing.value ??= bottle.pricing;
    } catch (_) {
      // Optional section: the page is complete without it.
    } finally {
      detailsLoading.value = false;
    }
  }

  Future<void> _loadCollectionOwnership() async {
    collectionLoading.value = true;
    try {
      final matches = await _findCollectionMatches();
      if (matches.isEmpty) {
        hasInCollection.value = false;
        collectionQuantity.value = 0;
        collectionFillRatio.value = 0;
        collectionPaidLabel.value = '—';
        collectionPriceMovementRaw.value = null;
        collectionGainDollars.value = null;
        return;
      }

      hasInCollection.value = true;
      var totalQty = 0;
      var totalPaid = 0.0;
      var fillSum = 0.0;
      String? movement;

      for (final item in matches) {
        final qtyRaw = int.tryParse(item.quantity ?? '');
        final qty = (qtyRaw == null || qtyRaw <= 0) ? 1 : qtyRaw;
        totalQty += qty;
        final unitPaid = double.tryParse(item.pricePaid ?? '') ?? 0;
        totalPaid += unitPaid * qty;
        fillSum += item.fillRatio;
        movement ??= item.priceMovementRaw;
      }

      collectionQuantity.value = totalQty;
      collectionFillRatio.value = (fillSum / matches.length).clamp(0.0, 1.0);
      collectionPaidLabel.value = PriceFormatter.format(
        totalPaid.round().toString(),
      );
      collectionPriceMovementRaw.value = movement ?? priceMovementRaw;

      final marketUnit = double.tryParse(
        (rawAverage ?? '').replaceAll(RegExp(r'[^\d.-]'), ''),
      );
      if (marketUnit != null && totalPaid > 0) {
        collectionGainDollars.value = (marketUnit * totalQty - totalPaid)
            .roundToDouble();
      } else {
        collectionGainDollars.value = null;
      }
    } catch (_) {
      hasInCollection.value = false;
    } finally {
      collectionLoading.value = false;
    }
  }

  Future<List<CollectionItemModel>> _findCollectionMatches() async {
    final selectedBottleId = bottleId;
    if (selectedBottleId == null ||
        selectedBottleId.isEmpty ||
        selectedBottleId == 'null') {
      return const [];
    }
    try {
      final all = await _collectionRepo.fetchMyCollection(forceRefresh: false);
      return all
          .where((item) => _resolveCollectionBottleId(item) == selectedBottleId)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// A real catalog id, so the bottle can go on the wishlist.
  bool get canWishlist => _canLoadPriceChart;

  bool get _canLoadPriceChart {
    final id = bottleId;
    return id != null && id.isNotEmpty && id != 'null';
  }

  Future<void> setChartRange(BenchmarkDetailChartRange range) async {
    if (selectedChartRange.value == range) return;
    selectedChartRange.value = range;
    await fetchPriceChart();
  }

  Future<void> fetchPriceChart() async {
    if (!_canLoadPriceChart) return;
    chartLoading.value = true;
    chartError.value = null;
    try {
      final range = selectedChartRange.value;
      final (from, to) = range.dateBoundsToToday();
      final rows = await _priceHistoryRepo.getChartDashboard(
        bottleId: bottleId!,
        fromDate: _formatChartApiDate(from),
        endDate: _formatChartApiDate(to),
      );
      BluebookPriceHistoryDashboardRow? matched;
      var next = <BluebookPriceChartPoint>[];
      for (final row in rows) {
        if (row.id == bottleId || row.bluebook?.id == bottleId) {
          matched = row;
          next = row.sortedPrices;
          break;
        }
      }
      if (next.isEmpty && rows.isNotEmpty) {
        matched = rows.first;
        next = rows.first.sortedPrices;
      }
      chartPoints.assignAll(next);
      _syncBsmiSeries(next);
      pricing.value = matched?.bluebook?.pricing ?? pricing.value;
    } catch (e) {
      // Keep the last good series on screen; only an empty chart shows the
      // error.
      if (chartPoints.isEmpty) chartError.value = e.toString();
    } finally {
      chartLoading.value = false;
    }
  }

  /// Change over the loaded chart window, first point to last, in percent.
  /// Null until at least two priced points are loaded. Unlike
  /// [priceMovementRaw] ("last change", which can be months old), this is
  /// the move over the range the user picked.
  double? get rangeChangePercent {
    final pts = chartPoints;
    if (pts.length < 2) return null;
    final first = pts.first.price;
    final last = pts.last.price;
    if (first <= 0 || last <= 0) return null;
    return (last - first) / first * 100;
  }

  void _syncBsmiSeries(List<BluebookPriceChartPoint> pts) {
    if (pts.isNotEmpty && pts.every((p) => p.bsmi != null)) {
      chartBsmiValues.assignAll(pts.map((p) => p.bsmi!));
    } else {
      chartBsmiValues.clear();
    }
  }

  static double? _money(String? raw) {
    final n = double.tryParse((raw ?? '').replaceAll(RegExp(r'[^\d.]'), ''));
    return n != null && n > 0 ? n : null;
  }

  static String? _nullableRouteString(String? value) {
    final t = value?.trim();
    if (t == null || t.isEmpty || t == 'null') return null;
    return t;
  }

  static String _resolveCollectionBottleId(CollectionItemModel item) {
    return item.bluebookBottleId ?? item.id;
  }

  Future<void> openAddToCollection() async {
    final result = await AddToCollectionLauncher(_collectionRepo).open(
      bottleId: bottleId,
      name: productName,
      imagePathOrUrl: imagePathOrUrl,
      averageRaw: rawAverage,
      popBenchmarkDetailOnSuccess: true,
    );
    if (result == true) {
      unawaited(_loadCollectionOwnership());
    }
  }
}
