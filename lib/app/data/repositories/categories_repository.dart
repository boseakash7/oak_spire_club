import '../datasources/categories_remote_datasource.dart';
import '../models/category_detail_model.dart';
import '../models/category_model.dart';
import '../models/paged_result.dart';

class CategoriesRepository {
  CategoriesRepository(this._remote);
  final CategoriesRemoteDataSource _remote;

  Future<PagedResult<CategoryModel>> list({
    required int page,
    required int limit,
  }) =>
      _remote.list(page: page, limit: limit);

  Future<CategoryDetailModel> detail({required String categoryId}) =>
      _remote.detail(categoryId: categoryId);
}

