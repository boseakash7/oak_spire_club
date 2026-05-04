import '../../core/storage/app_storage.dart';
import '../datasources/collection_remote_datasource.dart';
import '../models/collection_item_model.dart';

class CollectionRepository {
  CollectionRepository(this._remote);
  final CollectionRemoteDataSource _remote;

  Future<List<CollectionItemModel>> fetchMyCollection() async {
    final userId = AppStorage.userId;
    if (userId == null || userId.isEmpty) return [];
    return _remote.all(userId: userId, type: CollectionType.normal);
  }

  Future<Map<String, dynamic>?> fetchChartData({int lookBackDays = 90}) async {
    final userId = AppStorage.userId;
    if (userId == null || userId.isEmpty) return null;
    return _remote.chartData(userId: userId, lookBackDays: lookBackDays);
  }
}

