import 'package:get/get.dart';

import '../../core/cache/app_cache.dart';
import '../datasources/bluebook_remote_datasource.dart';
import '../models/bluebook_model.dart';

class BluebookRepository {
  BluebookRepository(this._remote);
  final BluebookRemoteDataSource _remote;
  static const Duration _ttl = Duration(hours: 24);

  Future<List<BluebookModel>> search({
    required int page,
    required int limit,
    String? keyword,
  }) =>
      _remote.getAll(page: page, limit: limit, keyword: keyword);

  Future<BluebookModel> create({
    required String bottleName,
    required String bottlePrice,
    required String userId,
  }) =>
      _remote.create(
        bottleName: bottleName,
        bottlePrice: bottlePrice,
        userId: userId,
      );

  Future<String?> lastUpdatedReadable({bool forceRefresh = false}) {
    final cache = Get.find<AppCache>();
    return cache.getOrFetch<String?>(
      cacheKey: 'bluebook:last-updated',
      ttl: _ttl,
      forceRefresh: forceRefresh,
      fetch: _remote.getLastUpdatedReadable,
      encode: (v) => <String, dynamic>{'readable': v},
      decode: (json) {
        if (json is Map<String, dynamic>) {
          return json['readable']?.toString();
        }
        if (json is Map) {
          return json['readable']?.toString();
        }
        return null;
      },
    );
  }
}

