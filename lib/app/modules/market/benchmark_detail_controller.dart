import 'dart:async';

import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/storage/app_storage.dart';
import '../../core/utils/greeting_formatter.dart';
import '../../core/utils/price_formatter.dart';
import '../../core/utils/proof_formatter.dart';
import '../session/user_session_controller.dart';
import '../../data/models/bluebook_price_history_chart_model.dart';
import '../../data/models/collection_item_display.dart';
import '../../data/models/collection_item_model.dart';
import '../../data/repositories/bluebook_price_history_repository.dart';
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

String? resolveBenchmarkDetailImageUrl(String? raw0) {
  final raw = raw0?.trim();
  if (raw == null || raw.isEmpty || raw == 'null') return null;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  final uploadUrl = AppStorage.uploadUrl;
  if (uploadUrl != null && uploadUrl.trim().isNotEmpty) {
    return '${uploadUrl.trim().replaceAll(RegExp(r'/+$'), '')}/$raw';
  }
  final api = Uri.parse(AppConstants.apiBaseUrl);
  return Uri(
    scheme: api.scheme,
    host: api.host,
    port: api.hasPort ? api.port : null,
    path: raw.startsWith('/') ? raw : '/$raw',
  ).toString();
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
  }) : _collectionRepo = collectionRepo,
        _priceHistoryRepo = priceHistoryRepo;

  final CollectionRepository _collectionRepo;
  final BluebookPriceHistoryRepository _priceHistoryRepo;
  late final String? bottleId;
  late final String productName;
  late final String? rawAverage;
  late final String avgFormatted;
  late final String lowFormatted;
  late final String highFormatted;
  late final String? imageUrl;
  late final String? imagePathOrUrl;
  late final String? proofText;
  late final String? descriptionText;
  late final String? ratingDisplay;
  late final String? priceMovementRaw;

  final selectedChartRange = BenchmarkDetailChartRange.y1.obs;
  final chartLoading = false.obs;
  final chartError = RxnString();
  final chartPoints = <BluebookPriceChartPoint>[].obs;
  /// Y values for BSMI line (same length as [chartPoints] when loaded).
  final chartBsmiValues = <double>[].obs;

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
    imagePathOrUrl = args.imagePathOrUrl;
    imageUrl = resolveBenchmarkDetailImageUrl(args.imagePathOrUrl);
    proofText = ProofFormatter.formatLabel(_nullableRouteString(args.proof));
    descriptionText = _nullableRouteString(args.description);
    ratingDisplay = _nullableRouteString(args.rating);
    priceMovementRaw = _nullableRouteString(args.priceMovement);
    if (_canLoadPriceChart) {
      unawaited(fetchPriceChart());
    }
    unawaited(_loadCollectionOwnership());
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
        collectionGainDollars.value =
            (marketUnit * totalQty - totalPaid).roundToDouble();
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
          .where(
            (item) => _resolveCollectionBottleId(item) == selectedBottleId,
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

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
      _syncBsmiSeries(matched, next);
    } catch (e) {
      chartError.value = e.toString();
      chartPoints.clear();
      chartBsmiValues.clear();
    } finally {
      chartLoading.value = false;
    }
  }

  void _syncBsmiSeries(
    BluebookPriceHistoryDashboardRow? row,
    List<BluebookPriceChartPoint> pts,
  ) {
    chartBsmiValues.clear();
    if (pts.isEmpty) return;

    final hasPerPoint = pts.every((p) => p.bsmi != null);
    if (hasPerPoint) {
      chartBsmiValues.addAll(pts.map((p) => p.bsmi!));
      return;
    }

    final avgStr = row?.bluebook?.average;
    final avg = double.tryParse((avgStr ?? '').replaceAll(RegExp(r'[^\d.-]'), ''));
    if (avg != null) {
      chartBsmiValues.addAll(List<double>.filled(pts.length, avg));
      return;
    }

    chartBsmiValues.addAll(pts.map((p) => p.price * 0.97));
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
