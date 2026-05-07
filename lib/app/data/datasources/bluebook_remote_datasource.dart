import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/bluebook_model.dart';

class BluebookRemoteDataSource {
  BluebookRemoteDataSource(this._client);
  final ApiClient _client;

  static const String _getAll = 'bluebook/get-all-bluebooks';
  static const String _create = 'bluebook/create';

  Future<List<BluebookModel>> getAll({
    required int page,
    required int limit,
    String? keyword,
  }) async {
    final response = await _client.get(_getAll, query: {
      'page': page.toString(),
      'limit': limit.toString(),
      if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
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
}

