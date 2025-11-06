import 'package:dio/dio.dart';

import 'api_interceptor.dart';
import 'network_exceptions.dart';

class ApiClient {
  final Dio dio;

  ApiClient({required String baseUrl})
      : dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  )) {
    dio.interceptors.add(ApiInterceptor());
  }

  void setAuthToken(String? token) {
    if (token == null || token.isEmpty) {
      dio.options.headers.remove('Authorization');
    } else {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Response> post(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final response = await dio.post(endpoint, data: data);
      return response;
    } on DioException catch (e) {
      throw NetworkExceptions.handleResponse(e);
    }
  }

  Future<Response> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await dio.get(endpoint, queryParameters: queryParams);
      return response;
    } on DioException catch (e) {
      throw NetworkExceptions.handleResponse(e);
    }
  }

  Future<Response> put(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final response = await dio.put(endpoint, data: data);
      return response;
    } on DioException catch (e) {
      throw NetworkExceptions.handleResponse(e);
    }
  }

  Future<Response> delete(String endpoint) async {
    try {
      final response = await dio.delete(endpoint);
      return response;
    } on DioException catch (e) {
      throw NetworkExceptions.handleResponse(e);
    }
  }
}
