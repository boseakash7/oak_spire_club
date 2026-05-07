import '../datasources/bluebook_remote_datasource.dart';
import '../models/bluebook_model.dart';

class BluebookRepository {
  BluebookRepository(this._remote);
  final BluebookRemoteDataSource _remote;

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
}

