import 'package:get/get.dart';

import '../constants/app_constants.dart';
import 'api_response_handler.dart';

class ApiClient extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = AppConstants.apiBaseUrl;
    httpClient.timeout = const Duration(seconds: 60);
    super.onInit();
  }

  /// Parses HTTP + `{ code: OK, data }` envelope. See [ApiResponseHandler].
  Map<String, dynamic> parseEnvelope(Response<dynamic> response) =>
      ApiResponseHandler.parseResponse(response);

  /// POST form body; returns full envelope after [ApiResponseHandler.ensureOk].
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await post(path, FormData(body));
    return parseEnvelope(response);
  }
}
