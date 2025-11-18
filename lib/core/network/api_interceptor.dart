import 'package:dio/dio.dart';
import 'dart:developer';
import '../ui/snackbar_service.dart';
import 'network_exceptions.dart';

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
    
    // Log response body for debugging
    if (err.response != null) {
      log("Response Data => ${err.response?.data}");
      log("Response Headers => ${err.response?.headers}");
    }
    
    try {
      final message = NetworkExceptions.handleResponse(err).message;
      SnackbarService.showError(message);
    } catch (_) {
      // Fallback: show dio's message if mapping fails
      if (err.message != null) {
        SnackbarService.showError(err.message!);
      }
    }
    super.onError(err, handler);
  }
}
