import 'dart:async';

import 'package:get/get.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../data/models/market_models.dart';
import '../../data/models/price_sparkline.dart';
import '../../data/repositories/bluebook_repository.dart';
import '../../data/repositories/market_repository.dart';

/// Chart range on an index's page; [days] is the server's `days`.
enum MarketIndexRange {
  m1(30, '1M'),
  m3(90, '3M'),
  m6(180, '6M'),
  y1(365, '1Y');

  const MarketIndexRange(this.days, this.label);

  final int days;
  final String label;
}

/// One Oak Spire index: its series for the picked range, the bottles that
/// moved it most, and how it is built. Route args `{slug, name}`.
class MarketIndexController extends GetxController {
  MarketIndexController({
    required MarketRepository marketRepo,
    required BluebookRepository bluebookRepo,
  }) : _marketRepo = marketRepo,
       _bluebookRepo = bluebookRepo;

  final MarketRepository _marketRepo;
  final BluebookRepository _bluebookRepo;

  late final String slug;

  /// From the route, so the title shows before the detail loads.
  late final String initialName;

  final range = MarketIndexRange.m3.obs;
  final detail = Rxn<MarketIndexDetail>();
  final isLoading = true.obs;
  final loadFailed = false.obs;
  final sparklines = <String, PriceSparkline>{}.obs;

  int _generation = 0;

  String get title => detail.value?.index?.name ?? initialName;

  /// Change over the loaded series, first point to last.
  double? get rangeChange {
    final series = detail.value?.index?.series ?? const <MarketIndexPoint>[];
    if (series.length < 2 || series.first.value <= 0) return null;
    return (series.last.value - series.first.value) / series.first.value * 100;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    final map = args is Map ? Map<String, dynamic>.from(args) : const {};
    slug = (map['slug'] ?? 'market').toString();
    initialName = (map['name'] ?? 'Index').toString();
    unawaited(load());
  }

  Future<void> setRange(MarketIndexRange value) async {
    if (range.value == value) return;
    range.value = value;
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(
        AppAnalyticsController.to.logTap('market_index_range', {
          'slug': slug,
          'days': value.days,
        }),
      );
    }
    await load();
  }

  Future<void> load({bool forceRefresh = false}) async {
    final generation = ++_generation;
    isLoading.value = true;
    try {
      final next = await _marketRepo.indexDetail(
        slug: slug,
        days: range.value.days,
        forceRefresh: forceRefresh,
      );
      if (generation != _generation) return;
      detail.value = next;
      loadFailed.value = false;
      _loadSparklines(next, forceRefresh: forceRefresh);
    } catch (_) {
      if (generation != _generation) return;
      // Keep the last good range on screen; only an empty page shows the error.
      loadFailed.value = detail.value == null;
    } finally {
      if (generation == _generation) isLoading.value = false;
    }
  }

  void _loadSparklines(MarketIndexDetail d, {required bool forceRefresh}) {
    final ids = {for (final b in [...d.risers, ...d.fallers]) b.id}.toList();
    if (ids.isEmpty) return;
    unawaited(
      _bluebookRepo
          .sparklines(ids, forceRefresh: forceRefresh)
          .then(sparklines.addAll),
    );
  }
}
