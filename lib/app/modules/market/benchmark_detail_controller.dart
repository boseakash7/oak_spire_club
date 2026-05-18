import 'dart:async';

import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/storage/app_storage.dart';
import '../../core/utils/price_formatter.dart';
import '../../data/models/bluebook_price_history_chart_model.dart';
import '../../data/models/collection_item_model.dart';
import '../../data/repositories/bluebook_price_history_repository.dart';
import '../../data/repositories/collection_repository.dart';
import '../../routes/app_routes.dart';
import '../collection/collection_controller.dart';
import '../home/home_controller.dart';

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

  final selectedChartRange = BenchmarkDetailChartRange.m1.obs;
  final chartLoading = false.obs;
  final chartError = RxnString();
  final chartPoints = <BluebookPriceChartPoint>[].obs;
  /// Y values for BSMI line (same length as [chartPoints] when loaded).
  final chartBsmiValues = <double>[].obs;

  String get userFirstName {
    final n = AppStorage.user?['first_name']?.toString().trim();
    if (n == null || n.isEmpty) return 'User';
    return n;
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
    proofText = _nullableRouteString(args.proof);
    descriptionText = _nullableRouteString(args.description);
    ratingDisplay = _nullableRouteString(args.rating);
    priceMovementRaw = _nullableRouteString(args.priceMovement);
    if (_canLoadPriceChart) {
      unawaited(fetchPriceChart());
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

  String _resolveCollectionBottleId(CollectionItemModel item) {
    final bbId = item.bluebook?['id']?.toString();
    if (bbId != null && bbId.isNotEmpty && bbId != 'null') return bbId;
    return item.id;
  }

  Future<void> openAddToCollection() async {
    final selectedBottleId = bottleId;
    if (selectedBottleId == null ||
        selectedBottleId.isEmpty ||
        selectedBottleId == 'null') {
      Get.toNamed(
        AppRoutes.addToCollection,
        arguments: {
          'prefill': {
            'name': productName,
            'average': rawAverage,
            'image': imagePathOrUrl,
          },
        },
      );
      return;
    }

    final prefill = <String, dynamic>{
      'id': selectedBottleId,
      'name': productName,
      'average': rawAverage,
      'image': imagePathOrUrl,
    };

    List<CollectionItemModel> matches = const <CollectionItemModel>[];
    try {
      final all = await _collectionRepo.fetchMyCollection(forceRefresh: true);
      matches = all
          .where((item) => _resolveCollectionBottleId(item) == selectedBottleId)
          .toList();
    } catch (_) {
      matches = const <CollectionItemModel>[];
    }

    if (matches.isNotEmpty) {
      int totalQty = 0;
      double totalPrice = 0;
      double totalFill = 0;
      int fillCount = 0;
      String? image;
      String? notes;
      String? dateAcquired;

      for (final item in matches) {
        final q = int.tryParse(item.quantity ?? '');
        totalQty += (q == null || q <= 0) ? 1 : q;
        totalPrice += double.tryParse(item.pricePaid ?? '') ?? 0;
        final fill = int.tryParse(item.fill ?? '');
        if (fill != null) {
          totalFill += fill;
          fillCount += 1;
        }
        image ??= item.image;
        notes ??= item.notes;
        dateAcquired ??= item.dateAcquired;
      }

      prefill['quantity'] = totalQty <= 0 ? 1 : totalQty;
      prefill['average'] = (totalPrice / matches.length).toStringAsFixed(2);
      if (fillCount > 0) {
        prefill['fill'] = (totalFill / fillCount).round().clamp(1, 100);
      }
      if (image != null && image.isNotEmpty) prefill['image'] = image;
      if (notes != null && notes.isNotEmpty) prefill['notes'] = notes;
      if (dateAcquired != null && dateAcquired.isNotEmpty) {
        prefill['date_acquired'] = dateAcquired;
      }
    }

    final result = await Get.toNamed(
      AppRoutes.addToCollection,
      arguments: {
        if (matches.isNotEmpty) 'editMode': true,
        if (matches.isNotEmpty) 'originalBottleId': selectedBottleId,
        'prefill': prefill,
      },
    );
    if (result == true) {
      if (Get.isRegistered<HomeController>()) {
        unawaited(
          Get.find<HomeController>().fetchHomeData(forceRefresh: false),
        );
      }
      if (Get.isRegistered<CollectionController>()) {
        unawaited(Get.find<CollectionController>().forceReload());
      }
    }
  }
}
