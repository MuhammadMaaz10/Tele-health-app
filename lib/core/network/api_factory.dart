import 'package:telehealth_app/core/network/dio_client.dart';
import 'package:telehealth_app/core/utils/app_endpoints.dart';

class ApiFactory {
  ApiFactory._();

  static final ApiClient _client = ApiClient(baseUrl: AppEndpoints.baseUrl);

  static ApiClient get client => _client;

  static void setAuthToken(String? token) {
    _client.setAuthToken(token);
  }
}


