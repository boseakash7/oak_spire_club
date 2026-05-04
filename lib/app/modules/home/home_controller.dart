import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/collection_repository.dart';

class HomeController extends GetxController {
  final hasCollection = false.obs;

  final collectionValueText = r'$ 2,36,5467'.obs;
  final movedText = 'Moved +64% in last 3 months'.obs;

  final totalCollectionCount = 54.obs;

  /// Chart series (last 9 points) in "k" units for display.
  final chartSeriesK = <double>[].obs;
  final chartMaxYk = 15.0.obs;

  final isLoading = false.obs;

  final _repo = Get.find<CollectionRepository>();

  @override
  void onInit() {
    super.onInit();
    fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    isLoading.value = true;
    try {
      final list = await _repo.fetchMyCollection();
      hasCollection.value = list.isNotEmpty;
      if (list.isNotEmpty) {
        totalCollectionCount.value = list.length;
      }

      final chart = await _repo.fetchChartData(lookBackDays: 90);
      if (chart != null) {
        final series = chart['data'];
        if (series is List && series.isNotEmpty) {
          final prices = <double>[];
          for (final item in series) {
            if (item is Map && item['price'] != null) {
              final p = double.tryParse(item['price'].toString());
              if (p != null) prices.add(p);
            }
          }
          if (prices.isNotEmpty) {
            final last = prices.length > 9 ? prices.sublist(prices.length - 9) : prices;
            final k = last.map((e) => e / 1000.0).toList();
            chartSeriesK.assignAll(k);

            final maxK = k.reduce((a, b) => a > b ? a : b);
            final rounded = ((maxK / 5).ceil() * 5).toDouble();
            chartMaxYk.value = rounded < 15 ? 15 : rounded;
          }
        }

        final first = double.tryParse(chart['first_price']?.toString() ?? '');
        final last = double.tryParse(chart['last_price']?.toString() ?? '');
        if (first != null && last != null && last != 0) {
          final percent = (100 - (first / last) * 100);
          final formatter = NumberFormat.currency(
            locale: 'en_US',
            symbol: r'$',
            decimalDigits: 0,
          );

          collectionValueText.value = formatter.format(last);
          movedText.value =
              'Moved ${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(0)}% in last 3 months';
        }
      }
    } catch (_) {
      // Keep hardcoded fallbacks on any failure.
    } finally {
      isLoading.value = false;
    }
  }
}

