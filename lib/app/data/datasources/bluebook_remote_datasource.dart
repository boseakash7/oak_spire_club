import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/bluebook_model.dart';

class BluebookRemoteDataSource {
  BluebookRemoteDataSource(this._client);
  final ApiClient _client;

  static const String _getAll = 'bluebook/get-all-bluebooks';

  /// Hybrid (typo-tolerant + semantic) search, same envelope as [_getAll].
  /// Falls back to the SQL search server-side, so it never fails harder
  /// than [_getAll] would.
  static const String _search = 'bluebook/search';
  static const String _create = 'bluebook/create';
  static const String _lastUpdate = 'bluebook/get-last-update';

  /// A page of the market list. With a [keyword] this is a search (ranked by
  /// relevance, typo tolerant); without one it browses alphabetically.
  /// [categoryId] filters either way.
  Future<List<BluebookModel>> getAll({
    required int page,
    required int limit,
    String? keyword,
    String? categoryId,
  }) async {
    final isSearch = keyword != null && keyword.trim().isNotEmpty;
    final response = await _client.get(isSearch ? _search : _getAll, query: {
      'page': page.toString(),
      'limit': limit.toString(),
      if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      if (categoryId != null && categoryId.trim().isNotEmpty)
        'category_id': categoryId.trim(),
    });

    final json = _client.parseEnvelope(response);

    final data = json['data'];
    if (data is! Map) throw ApiException('Unexpected server response.');
    final list = data['data'];
    if (list is! List) throw ApiException('Unexpected server response.');

    return list
        .whereType<Map>()
        .map((e) => BluebookModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<BluebookModel> create({
    required String bottleName,
    required String bottlePrice,
    required String userId,
  }) async {
    final json = await _client.postJson(_create, {
      'bottle_name': bottleName,
      'bottle_price': bottlePrice,
      'user_id': userId,
    });

    final data = json['data'];
    if (data is! Map) throw ApiException('Unexpected server response.');
    return BluebookModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<String?> getLastUpdatedReadable() async {
    final response = await _client.get(_lastUpdate);
    final json = _client.parseEnvelope(response);

    final data = json['data'];
    if (data is! Map) return null;
    return data['readable']?.toString();
  }
}

