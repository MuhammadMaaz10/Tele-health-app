import 'package:dio/dio.dart';

class NetworkExceptions implements Exception {
  final String message;
  NetworkExceptions(this.message);

  static NetworkExceptions handleResponse(DioException e) {
    if (e.response == null) {
      // No response = network or DNS or SSL issue
      return NetworkExceptions("Network error: ${e.message}");
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
