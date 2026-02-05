import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NetworkExceptions implements Exception {
  final String message;
  NetworkExceptions(this.message);

  static NetworkExceptions handleResponse(DioException e) {
    // Handle connection errors (CORS, network issues, etc.)
    if (e.response == null) {
      final errorMessage = e.message ?? '';
      
      // Detect CORS errors on web
      if (kIsWeb && 
          (e.type == DioExceptionType.connectionError || 
           errorMessage.contains('XMLHttpRequest') ||
           errorMessage.contains('CORS') ||
           errorMessage.contains('cross-origin'))) {
        return NetworkExceptions(
          "Connection blocked: The server is not configured to accept requests from this web app. "
          "This is a server configuration issue (CORS). Please contact support or try using the mobile app."
        );
      }
      
      // Generic connection error
      if (e.type == DioExceptionType.connectionError) {
        return NetworkExceptions(
          "Connection Error: Unable to reach the server. "
          "Please check your internet connection and try again."
        );
      }
      
      // Network or DNS or SSL issue
      return NetworkExceptions("Network error: ${errorMessage.isNotEmpty ? errorMessage : 'Unable to connect to server'}");
    }

    final statusCode = e.response?.statusCode ?? 0;
    // Try to get error message from different possible locations
    dynamic responseData = e.response?.data;
    String msg = "Unknown error";
    
    if (responseData is Map) {
      msg = responseData['message'] ?? 
            responseData['error'] ?? 
            responseData['detail'] ?? 
            responseData.toString();
    } else if (responseData is String) {
      msg = responseData;
    } else {
      msg = e.message ?? "Unknown error";
    }

    switch (statusCode) {
      case 400:
        return NetworkExceptions("Bad Request: $msg");
      case 401:
        return NetworkExceptions("Unauthorized: $msg");
      case 403:
        return NetworkExceptions("Forbidden: $msg");
      case 404:
        return NetworkExceptions("Not Found: $msg");
      case 500:
        return NetworkExceptions("Server Error: $msg");
      default:
        return NetworkExceptions("HTTP $statusCode: $msg");
    }
  }

  @override
  String toString() => message;
}
