import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/bluebook_price_history_chart_model.dart';

class BluebookPriceHistoryRemoteDataSource {
  BluebookPriceHistoryRemoteDataSource(this._client);
  final ApiClient _client;

  static const String _chartDashboard =
      'bluebook-price-history/chart-data-dashboard';

  Future<List<BluebookPriceHistoryDashboardRow>> getChartDashboard({
    required String bottleId,
    required String fromDate,
    required String endDate,
  }) async {
    final response = await _client.get(
      _chartDashboard,
      query: {
        'bottleId': bottleId,
        'fromDate': fromDate,
        'endDate': endDate,
      },
    );

    final json = _client.parseEnvelope(response);

    final data = json['data'];
    if (data is! Map) throw ApiException('Unexpected server response.');
    final list = data['data'];
    if (list is! List) throw ApiException('Unexpected server response.');

    return list
        .whereType<Map>()
        .map(
          (e) => BluebookPriceHistoryDashboardRow.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }
}
