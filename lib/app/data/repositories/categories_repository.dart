import 'package:get/get.dart';

import '../../core/cache/app_cache.dart';
import '../datasources/categories_remote_datasource.dart';
import '../models/category_detail_model.dart';
import '../models/category_model.dart';
import '../models/paged_result.dart';

class CategoriesRepository {
  CategoriesRepository(this._remote);
  final CategoriesRemoteDataSource _remote;
  static const Duration _ttl = Duration(hours: 24);

  Future<PagedResult<CategoryModel>> list({
    required int page,
    required int limit,
    bool forceRefresh = false,
  }) async {
    final cache = Get.find<AppCache>();
    return cache.getOrFetch<PagedResult<CategoryModel>>(
      cacheKey: 'categories:list:$page:$limit',
      ttl: _ttl,
      forceRefresh: forceRefresh,
      fetch: () => _remote.list(page: page, limit: limit),
      encode: (v) => {
        'total_items': v.totalItems,
        'limit': v.limit,
        'current_page': v.currentPage,
        'offset': v.offset,
        'total_pages': v.totalPages,
        'data': v.items.map((e) => e.toJson()).toList(),
      },
      decode: (json) {
        if (json is! Map) {
          return PagedResult<CategoryModel>(
            totalItems: 0,
            limit: limit,
            currentPage: page,
            offset: 0,
            totalPages: 1,
            items: const [],
          );
        }
        final m = Map<String, dynamic>.from(json);
        final data = m['data'];
        final items = (data is List)
            ? data
                .whereType<Map>()
                .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : <CategoryModel>[];
        return PagedResult<CategoryModel>(
          totalItems: int.tryParse(m['total_items']?.toString() ?? '') ?? items.length,
          limit: int.tryParse(m['limit']?.toString() ?? '') ?? limit,
          currentPage: int.tryParse(m['current_page']?.toString() ?? '') ?? page,
          offset: int.tryParse(m['offset']?.toString() ?? '') ?? 0,
          totalPages: int.tryParse(m['total_pages']?.toString() ?? '') ?? 1,
          items: items,
        );
      },
    );
  }

  Future<CategoryDetailModel> detail({
    required String categoryId,
    bool forceRefresh = false,
  }) async {
    final cache = Get.find<AppCache>();
    return cache.getOrFetch<CategoryDetailModel>(
      cacheKey: 'categories:detail:$categoryId',
      ttl: _ttl,
      forceRefresh: forceRefresh,
      fetch: () => _remote.detail(categoryId: categoryId),
      encode: (v) => v.toJson(),
      decode: (json) => CategoryDetailModel.fromJson(
        json is Map<String, dynamic>
            ? json
            : Map<String, dynamic>.from(json as Map),
      ),
    );
  }
}

