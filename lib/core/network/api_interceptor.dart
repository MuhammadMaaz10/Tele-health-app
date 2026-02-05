import 'package:dio/dio.dart';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import '../ui/snackbar_service.dart';
import '../utils/shared_preferences_service.dart';
import 'api_factory.dart';
import 'network_exceptions.dart';
import '../../features/auth/login/view/login_view.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Ensure token is set from SharedPreferences on each request (web/desktop safety)
    final token = await SharedPreferencesService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
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
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    log("🔴 ERROR => ${err.requestOptions.uri}");
    log("Type => ${err.type}");
    log("Status => ${err.response?.statusCode}");
    log("Error => ${err.response?.data}");
    log("Message => ${err.message}");
    
    // Log response body for debugging
    if (err.response != null) {
      log("Response Data => ${err.response?.data}");
      log("Response Headers => ${err.response?.headers}");
    } else {
      // Connection error - likely CORS on web
      if (err.type == DioExceptionType.connectionError) {
        log("⚠️ Connection Error - This might be a CORS issue on web");
        log("Request URL: ${err.requestOptions.uri}");
        log("Request Method: ${err.requestOptions.method}");
      }
    }
    
    // Handle 401 Unauthorized - token might be missing or expired
    if (err.response?.statusCode == 401) {
      log("⚠️ 401 Unauthorized - Token expired or invalid");
      
      // For 401, always clear auth and redirect (token is invalid or expired)
      log("❌ 401 Unauthorized - Clearing auth data and redirecting to login");
      await SharedPreferencesService.clearAuthData();
      ApiFactory.clearAuthToken();
      
      // Navigate to login screen - Use microtask to ensure it runs on the main thread
      // This works reliably on both mobile and web
      Future.microtask(() {
        try {
          // Schedule navigation for next frame to ensure context is available
          // This approach works reliably on both mobile and web
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              // Use GetX navigation - works on both platforms
              Get.offAll(() => LoginView());
              log("🔄 Redirected to login screen");
            } catch (e) {
              log("⚠️ Could not navigate to login: $e");
              // Fallback: Try direct navigation if GetX fails
              try {
                final context = Get.context;
                if (context != null) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => LoginView()),
                    (route) => false,
                  );
                  log("🔄 Redirected to login screen via Navigator fallback");
                }
              } catch (e2) {
                log("⚠️ All navigation attempts failed: $e2");
              }
            }
          });
        } catch (e) {
          log("⚠️ Navigation scheduling error: $e");
        }
      });
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
