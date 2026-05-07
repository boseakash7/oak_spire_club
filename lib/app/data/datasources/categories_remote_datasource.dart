import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/category_detail_model.dart';
import '../models/category_model.dart';
import '../models/paged_result.dart';

class CategoriesRemoteDataSource {
  CategoriesRemoteDataSource(this._client);
  final ApiClient _client;

  static const String _list = 'categories/list';
  static const String _detail = 'categories/detail';

  Future<PagedResult<CategoryModel>> list({
    required int page,
    required int limit,
  }) async {
    final response = await _client.post(
      _list,
      FormData({}),
      query: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    if (response.statusCode != 200) {
      throw ApiException('Internal server error.');
    }

    final json = response.body;
    if (json is! Map) throw ApiException('Unexpected server response.');
    if (json['code']?.toString() != 'OK') {
      throw ApiException(json['data']?.toString() ?? 'Something went wrong.');
    }

    final data = json['data'];
    if (data is! Map) throw ApiException('Unexpected server response.');

    final itemsRaw = data['data'];
    if (itemsRaw is! List) throw ApiException('Unexpected server response.');

    final items = itemsRaw
        .whereType<Map>()
        .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return PagedResult<CategoryModel>(
      totalItems: int.tryParse(data['total_items']?.toString() ?? '') ?? items.length,
      limit: int.tryParse(data['limit']?.toString() ?? '') ?? limit,
      currentPage: int.tryParse(data['current_page']?.toString() ?? '') ?? page,
      offset: int.tryParse(data['offset']?.toString() ?? '') ?? 0,
      totalPages: int.tryParse(data['total_pages']?.toString() ?? '') ?? 1,
      items: items,
    );
  }

  Future<CategoryDetailModel> detail({required String categoryId}) async {
    final response = await _client.get(_detail, query: {
      'category_id': categoryId,
    });

    if (response.statusCode != 200) {
      throw ApiException('Internal server error.');
    }

    final json = response.body;
    if (json is! Map) throw ApiException('Unexpected server response.');
    if (json['code']?.toString() != 'OK') {
      throw ApiException(json['data']?.toString() ?? 'Something went wrong.');
    }

    final data = json['data'];
    if (data is! Map) throw ApiException('Unexpected server response.');
    return CategoryDetailModel.fromJson(Map<String, dynamic>.from(data));
  }
}

