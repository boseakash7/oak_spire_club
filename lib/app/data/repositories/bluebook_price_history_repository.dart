import '../datasources/bluebook_price_history_remote_datasource.dart';
import '../models/bluebook_price_history_chart_model.dart';

class BluebookPriceHistoryRepository {
  BluebookPriceHistoryRepository(this._remote);
  final BluebookPriceHistoryRemoteDataSource _remote;

  Future<List<BluebookPriceHistoryDashboardRow>> getChartDashboard({
    required String bottleId,
    required String fromDate,
    required String endDate,
  }) =>
      _remote.getChartDashboard(
        bottleId: bottleId,
        fromDate: fromDate,
        endDate: endDate,
      );
}
