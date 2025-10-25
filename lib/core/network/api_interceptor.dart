import 'package:dio/dio.dart';
import 'dart:developer';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log("🔵 REQUEST => ${options.method} ${options.uri}");
    log("Headers => ${options.headers}");
    log("Body => ${options.data}");
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log("🟢 RESPONSE => ${response.statusCode} ${response.requestOptions.uri}");
    log("Response Body => ${response.data}");
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log("🔴 ERROR => ${err.requestOptions.uri}");
    log("Type => ${err.type}");
    log("Status => ${err.response?.statusCode}");
    log("Error => ${err.response?.data}");
    log("Message => ${err.message}");
    super.onError(err, handler);
  }
}
