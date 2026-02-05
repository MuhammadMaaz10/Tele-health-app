import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:telehealth_app/core/network/api_factory.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/core/utils/app_endpoints.dart';
import '../model/appointment_model.dart';
import '../model/appointment_note_model.dart';

class AppointmentApi {
  final _client = ApiFactory.client;

  /// Create a new appointment
  /// Validates that appointment is within 14 days from current date
  Future<AppointmentResponse> createAppointment({
    required String doctorEmail,
    required String patientEmail,
    required String shortDescription,
    required String date,
    required String time,
    required String appointmentStartTime,
    required String appointmentEndTime,
  }) async {
    try {
      final requestData = {
        'doctorEmail': doctorEmail,
        'patientEmail': patientEmail,
        'shortDescription': shortDescription,
        'date': date,
        'time': time,
        'appointmentStartTime': appointmentStartTime,
        'appointmentEndTime': appointmentEndTime,
      };

      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: ${AppEndpoints.createAppointment}');
      debugPrint('Method: POST');
      debugPrint('Request Body:');
      requestData.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      debugPrint('=================================\n');

      final Response response = await _client.post(
        AppEndpoints.createAppointment,
        data: requestData,
      );

      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
      return AppointmentResponse.fromJson(data);
    } on NetworkExceptions {
      rethrow;
    }
  }

  /// Get all appointments for a user by email
  Future<List<Appointment>> getMyAppointments(String email) async {
    try {
      // URL-encode the email to handle special characters like @ in path parameters
      final encodedEmail = Uri.encodeComponent(email);
      final endpoint = '${AppEndpoints.getMyAppointments}/$encodedEmail';

      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: $endpoint');
      debugPrint('Method: GET');
      debugPrint('=================================\n');

      final Response response = await _client.get(endpoint);

      if (response.data is List) {
        final List<dynamic> data = response.data as List;
        return data
            .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on NetworkExceptions {
      rethrow;
    }
  }

  /// Update/Reschedule an appointment
  Future<Appointment> updateAppointment({
    required int appointmentId,
    required String doctorEmail,
    required String patientEmail,
    required String newDate,
    required String newTime,
  }) async {
    try {
      final endpoint = '${AppEndpoints.updateAppointment}/$appointmentId';
      final requestData = {
        'doctorEmail': doctorEmail,
        'patientEmail': patientEmail,
        'newDate': newDate,
        'newTime': newTime,
      };

      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: $endpoint');
      debugPrint('Method: PUT');
      debugPrint('Request Body:');
      requestData.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      debugPrint('=================================\n');

      final Response response = await _client.put(
        endpoint,
        data: requestData,
      );

      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
      return Appointment.fromJson(data);
    } on NetworkExceptions {
      rethrow;
    }
  }

  /// Cancel an appointment
  Future<AppointmentResponse> cancelAppointment(int appointmentId) async {
    try {
      final endpoint = '${AppEndpoints.cancelAppointment}/$appointmentId';

      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: $endpoint');
      debugPrint('Method: PUT');
      debugPrint('=================================\n');

      final Response response = await _client.put(endpoint);

      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
      return AppointmentResponse.fromJson(data);
    } on NetworkExceptions {
      rethrow;
    }
  }

  /// Confirm an appointment
  Future<AppointmentResponse> confirmAppointment(int appointmentId) async {
    try {
      final endpoint = '${AppEndpoints.confirmAppointment}/$appointmentId';

      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: $endpoint');
      debugPrint('Method: PUT');
      debugPrint('=================================\n');

      final Response response = await _client.put(endpoint);

      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
      return AppointmentResponse.fromJson(data);
    } on NetworkExceptions {
      rethrow;
    }
  }

  /// Add notes to an appointment
  Future<AppointmentNoteResponse> addAppointmentNotes({
    required int appointmentId,
    required String noteType,
    required String clinicalNotes,
    required String diagnosis,
    required String treatmentPlan,
    required String observations,
  }) async {
    try {
      final endpoint = '${AppEndpoints.addAppointmentNotes}/$appointmentId/notes';
      final requestData = {
        'noteType': noteType,
        'clinicalNotes': clinicalNotes,
        'diagnosis': diagnosis,
        'treatmentPlan': treatmentPlan,
        'observations': observations,
      };

      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: $endpoint');
      debugPrint('Method: POST');
      debugPrint('Request Body:');
      requestData.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      debugPrint('=================================\n');

      final Response response = await _client.post(
        endpoint,
        data: requestData,
      );

      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
      return AppointmentNoteResponse.fromJson(data);
    } on NetworkExceptions {
      rethrow;
    }
  }

  /// Get all appointment notes by user email
  Future<List<AppointmentNote>> getAppointmentNotesByEmail() async {
    try {
      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: ${AppEndpoints.getAppointmentNotes}');
      debugPrint('Method: GET');
      debugPrint('=================================\n');

      final Response response = await _client.get(AppEndpoints.getAppointmentNotes);

      if (response.data is List) {
        final List<dynamic> data = response.data as List;
        return data
            .map((json) => AppointmentNote.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on NetworkExceptions {
      rethrow;
    }
  }

  /// Update an appointment note
  Future<AppointmentNoteResponse> updateAppointmentNote({
    required int appointmentId,
    required int noteId,
    required String noteType,
    required String clinicalNotes,
    required String diagnosis,
    required String treatmentPlan,
    required String observations,
  }) async {
    try {
      final endpoint = '${AppEndpoints.updateAppointmentNote}/$appointmentId/notes/$noteId';
      final requestData = {
        'noteType': noteType,
        'clinicalNotes': clinicalNotes,
        'diagnosis': diagnosis,
        'treatmentPlan': treatmentPlan,
        'observations': observations,
      };

      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: $endpoint');
      debugPrint('Method: PUT');
      debugPrint('Request Body:');
      requestData.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      debugPrint('=================================\n');

      final Response response = await _client.put(
        endpoint,
        data: requestData,
      );

      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
      return AppointmentNoteResponse.fromJson(data);
    } on NetworkExceptions {
      rethrow;
    }
  }

  /// Delete an appointment note
  Future<AppointmentNoteResponse> deleteAppointmentNote({
    required int appointmentId,
    required int noteId,
  }) async {
    try {
      final endpoint = '${AppEndpoints.deleteAppointmentNote}/$appointmentId/notes/$noteId';

      debugPrint('========== API REQUEST ==========');
      debugPrint('Endpoint: $endpoint');
      debugPrint('Method: DELETE');
      debugPrint('=================================\n');

      final Response response = await _client.delete(endpoint);

      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
      return AppointmentNoteResponse.fromJson(data);
    } on NetworkExceptions {
      rethrow;
    }
  }
}



