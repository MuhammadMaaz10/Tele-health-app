import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:telehealth_app/core/network/api_factory.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/core/utils/app_endpoints.dart';

class AuthApi {
  final _client = ApiFactory.client;

  Future<Map<String, dynamic>> login({required String email}) async {
    try {
      final requestData = {'email': email};
      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: ${AppEndpoints.login}');
      debugPrint('Method: POST');
      debugPrint('Request Body:');
      requestData.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      debugPrint('=================================\n');
      
      final Response response = await _client.post(
        AppEndpoints.login,
        data: requestData,
      );
      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
      return data;
    } on NetworkExceptions {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resendOtp({required String email}) async {
    try {
      final requestData = {'email': email};
      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: ${AppEndpoints.resendOtp}');
      debugPrint('Method: POST');
      debugPrint('Request Body:');
      requestData.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      debugPrint('=================================\n');

      final Response response = await _client.post(
        AppEndpoints.resendOtp,
        data: requestData,
      );
      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
      return data;
    } on NetworkExceptions {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkUser({required String email, required String role}) async {
    try {
      final requestData = {
        'email': email,
        'role': role,
      };
      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: ${AppEndpoints.checkUser}');
      debugPrint('Method: POST');
      debugPrint('Request Body:');
      requestData.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      debugPrint('=================================\n');
      
      final Response response = await _client.post(
        AppEndpoints.checkUser,
        data: requestData,
      );
      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
      return data;
    } on NetworkExceptions {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    String? role,
  })
  async {
    try {
      final requestData = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        if (role != null) 'role': role,
      };
      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: ${AppEndpoints.signup}');
      debugPrint('Method: POST');
      debugPrint('Request Body:');
      requestData.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      debugPrint('=================================\n');
      
      final Response response = await _client.post(
        AppEndpoints.signup,
        data: requestData,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on NetworkExceptions {
      rethrow;
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      final requestData = {'email': email};
      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: ${AppEndpoints.forgotPassword}');
      debugPrint('Method: POST');
      debugPrint('Request Body:');
      requestData.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      debugPrint('=================================\n');

      await _client.post(AppEndpoints.forgotPassword, data: requestData);
    } on NetworkExceptions {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyLoginOtp({required String email, required String otp}) async {
    try {
      final requestData = {'email': email, 'otp': otp};
      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: ${AppEndpoints.verifyLoginOtp}');
      debugPrint('Method: POST');
      debugPrint('Request Body:');
      requestData.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      debugPrint('=================================\n');
      
      final Response response = await _client.post(
        AppEndpoints.verifyLoginOtp,
        data: requestData,
      );
      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
      final String? token = data['token'] as String?;
      if (token != null) {
        ApiFactory.setAuthToken(token);
      }
      return data;
    } on NetworkExceptions {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyRegisterOtp({required String email, required String otp}) async {
    try {
      final requestData = {'email': email, 'otp': otp};
      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: ${AppEndpoints.verifyRegistrationOtp}');
      debugPrint('Method: POST');
      debugPrint('Request Body:');
      requestData.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      debugPrint('=================================\n');
      
      final Response response = await _client.post(
        AppEndpoints.verifyRegistrationOtp,
        data: requestData,
      );
      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
      final String? token = data['token'] as String?;
      if (token != null) {
        ApiFactory.setAuthToken(token);
      }
      return data;
    } on NetworkExceptions {
      rethrow;
    }
  }

  Future<void> resetPassword({required String email, required String newPassword}) async {
    try {
      final requestData = {
        'email': email,
        'password': newPassword,
      };
      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: ${AppEndpoints.resetPassword}');
      debugPrint('Method: POST');
      debugPrint('Request Body:');
      requestData.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      debugPrint('=================================\n');
      
      await _client.post(AppEndpoints.resetPassword, data: requestData);
    } on NetworkExceptions {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerPatient({
    required FormData formData,
    required double? latitude,
    required double? longitude,
  })
  async {
    try {
      // Build URL with location query parameter as JSON object
      String url = AppEndpoints.registerPatient;
      if (latitude != null && longitude != null) {
        // Format: {"latitude": lat, "longitude": lng}
        final locationJson = '{"latitude": $latitude, "longitude": $longitude}';
        url += '?location=${Uri.encodeComponent(locationJson)}';
      }
      
      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: $url');
      debugPrint('Method: POST');
      debugPrint('Content-Type: multipart/form-data');
      debugPrint('Location Query: {"latitude": $latitude, "longitude": $longitude}');
      debugPrint('\n--- Form Fields ---');
      for (var field in formData.fields) {
        debugPrint('  ${field.key}: ${field.value}');
      }
      debugPrint('\n--- Form Files ---');
      for (var file in formData.files) {
        debugPrint('  ${file.key}: ${file.value.filename} (${file.value.length} bytes)');
      }
      debugPrint('=================================\n');
      
      final Response response = await ApiFactory.dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Accept': '*/*',
          },
        ),
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on NetworkExceptions {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerDoctor({
    required FormData formData,
    required double? latitude,
    required double? longitude,
  }) async {
    try {
      // Build URL with location query parameter as JSON object
      String url = AppEndpoints.registerDoctor;
      if (latitude != null && longitude != null) {
        // Format: {"latitude": lat, "longitude": lng}
        final locationJson = '{"latitude": $latitude, "longitude": $longitude}';
        url += '?location=${Uri.encodeComponent(locationJson)}';
      }
      
      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: $url');
      debugPrint('Method: POST');
      debugPrint('Content-Type: multipart/form-data');
      debugPrint('Location Query: {"latitude": $latitude, "longitude": $longitude}');
      debugPrint('\n--- Form Fields ---');
      for (var field in formData.fields) {
        debugPrint('  ${field.key}: ${field.value}');
      }
      debugPrint('\n--- Form Files ---');
      for (var file in formData.files) {
        debugPrint('  ${file.key}: ${file.value.filename} (${file.value.length} bytes)');
      }
      debugPrint('=================================\n');
      
      final Response response = await ApiFactory.dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Accept': '*/*',
          },
        ),
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on NetworkExceptions {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerNurse({
    required FormData formData,
    required double? latitude,
    required double? longitude,
  }) async {
    try {
      // Build URL with location query parameter as JSON object
      String url = AppEndpoints.registerNurse;
      if (latitude != null && longitude != null) {
        // Format: {"latitude": lat, "longitude": lng}
        final locationJson = '{"latitude": $latitude, "longitude": $longitude}';
        url += '?location=${Uri.encodeComponent(locationJson)}';
      }
      
      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: $url');
      debugPrint('Method: POST');
      debugPrint('Content-Type: multipart/form-data');
      debugPrint('Location Query: {"latitude": $latitude, "longitude": $longitude}');
      debugPrint('\n--- Form Fields ---');
      for (var field in formData.fields) {
        debugPrint('  ${field.key}: ${field.value}');
      }
      debugPrint('\n--- Form Files ---');
      for (var file in formData.files) {
        debugPrint('  ${file.key}: ${file.value.filename} (${file.value.length} bytes)');
      }
      debugPrint('=================================\n');
      
      final Response response = await ApiFactory.dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Accept': '*/*',
          },
        ),
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on NetworkExceptions {
      rethrow;
    }
  }
}


