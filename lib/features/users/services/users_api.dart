import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:telehealth_app/core/network/api_factory.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/core/utils/app_endpoints.dart';
import 'package:telehealth_app/features/profile/model/profile_model.dart';

class UsersApi {
  final _client = ApiFactory.client;

  /// Get all doctors
  Future<List<User>> getDoctors() async {
    try {
      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: ${AppEndpoints.getDoctors}');
      debugPrint('Method: GET');
      debugPrint('=================================\n');

      final Response response = await _client.get(AppEndpoints.getDoctors);

      if (response.data is List) {
        final List<dynamic> data = response.data as List;
        return data
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on NetworkExceptions {
      rethrow;
    }
  }

  /// Get all patients
  Future<List<User>> getPatients() async {
    try {
      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: ${AppEndpoints.getPatients}');
      debugPrint('Method: GET');
      debugPrint('=================================\n');

      final Response response = await _client.get(AppEndpoints.getPatients);

      if (response.data is List) {
        final List<dynamic> data = response.data as List;
        return data
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on NetworkExceptions {
      rethrow;
    }
  }

  /// Get all nurses
  Future<List<User>> getNurses() async {
    try {
      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: ${AppEndpoints.getNurses}');
      debugPrint('Method: GET');
      debugPrint('=================================\n');

      final Response response = await _client.get(AppEndpoints.getNurses);

      if (response.data is List) {
        final List<dynamic> data = response.data as List;
        return data
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on NetworkExceptions {
      rethrow;
    }
  }
}









