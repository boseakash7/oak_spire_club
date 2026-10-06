import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

/// The market screens' endpoints (oakspireweb `Api\Market`). Returns raw
/// `data` maps; [MarketRepository] caches and parses them.
class MarketRemoteDataSource {
  MarketRemoteDataSource(this._client);
  final ApiClient _client;

  /// Headline index + biggest movers over `days` (30 / 90 / 365).
  static const String _overview = 'market/overview';

  /// Every Oak Spire index with its 90-day series.
  static const String _indexes = 'market/indexes';

  /// One index: series for `days` (30 / 90 / 180 / 365), risers, fallers,
  /// methodology.
  static const String _indexDetail = 'market/index-detail';

  /// Market breadth over `days` (30 / 90 / 365) plus the Home tab's lists:
  /// hot with collectors, newly priced, most collected, top rated.
  static const String _highlights = 'market/highlights';

  Future<Map<String, dynamic>> overview({int days = 30}) async {
    final response = await _client.get(
      _overview,
      query: {'days': days.toString()},
    );
    return _dataMap(_client.parseEnvelope(response));
  }

  Future<List<Map<String, dynamic>>> indexes() async {
    final response = await _client.get(_indexes);
    final data = _client.parseEnvelope(response)['data'];
    if (data is! List) throw ApiException('Unexpected server response.');
    return [
      for (final e in data.whereType<Map>()) Map<String, dynamic>.from(e),
    ];
  }

  Future<Map<String, dynamic>> indexDetail({
    required String slug,
    required int days,
  }) async {
    final response = await _client.get(
      _indexDetail,
      query: {'slug': slug, 'days': days.toString()},
    );
    return _dataMap(_client.parseEnvelope(response));
  }

  Future<Map<String, dynamic>> highlights({int days = 30}) async {
    final response = await _client.get(
      _highlights,
      query: {'days': days.toString()},
    );
    return _dataMap(_client.parseEnvelope(response));
  }

  static Map<String, dynamic> _dataMap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) throw ApiException('Unexpected server response.');
    return Map<String, dynamic>.from(data);
  }
}
