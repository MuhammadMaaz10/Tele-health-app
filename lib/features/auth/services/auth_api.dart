import 'package:dio/dio.dart';
import 'package:telehealth_app/core/network/api_factory.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/core/utils/app_endpoints.dart';

class AuthApi {
  final _client = ApiFactory.client;

  Future<Map<String, dynamic>> login({required String email}) async {
    try {
      final Response response = await _client.post(
        AppEndpoints.login,
        data: {
          'email': email,
        },
      );
      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
      return data;
    } on NetworkExceptions {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkUser({required String email, required String role}) async {
    try {
      final Response response = await _client.post(
        AppEndpoints.checkUser,
        data: {
          'email': email,
          'role': role,
        },
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
  }) async {
    try {
      final Response response = await _client.post(
        AppEndpoints.signup,
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (role != null) 'role': role,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on NetworkExceptions {
      rethrow;
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _client.post(AppEndpoints.forgotPassword, data: {'email': email});
    } on NetworkExceptions {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyOtp({required String email, required String otp}) async {
    try {
      final Response response = await _client.post(
        AppEndpoints.verifyOtp,
        data: {'email': email, 'otp': otp},
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
      await _client.post(AppEndpoints.resetPassword, data: {
        'email': email,
        'password': newPassword,
      });
    } on NetworkExceptions {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerPatient({required Map<String, dynamic> payload}) async {
    try {
      final Response response = await _client.post(AppEndpoints.registerPatient, data: payload);
      return Map<String, dynamic>.from(response.data as Map);
    } on NetworkExceptions {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerDoctor({required Map<String, dynamic> payload}) async {
    try {
      final Response response = await _client.post(AppEndpoints.registerDoctor, data: payload);
      return Map<String, dynamic>.from(response.data as Map);
    } on NetworkExceptions {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerNurse({required Map<String, dynamic> payload}) async {
    try {
      final Response response = await _client.post(AppEndpoints.registerNurse, data: payload);
      return Map<String, dynamic>.from(response.data as Map);
    } on NetworkExceptions {
      rethrow;
    }
  }
}


