import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/appointment_model.dart';
import '../model/appointment_note_model.dart';

class AppointmentApi {
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
    String? status,
  }) async {
    try {
      debugPrint('========== SUPABASE RPC ==========');
      debugPrint('Function: app_create_appointment');
      debugPrint('==================================\n');

      final dynamic raw = await Supabase.instance.client.rpc(
        'app_create_appointment',
        params: {
          'p_doctor_email': doctorEmail,
          'p_patient_email': patientEmail,
          'p_short_description': shortDescription,
          'p_appointment_start_time': appointmentStartTime,
          'p_appointment_end_time': appointmentEndTime,
          'p_appointment_time': time,
          'p_status': (status != null && status.isNotEmpty) ? status : 'PENDING',
        },
      );

      final rows = raw as List<dynamic>;
      if (rows.isEmpty) {
        return AppointmentResponse(message: 'Failed to create appointment', status: 'FAILED');
      }
      final appointment = Appointment.fromJson(Map<String, dynamic>.from(rows.first as Map));
      return AppointmentResponse(
        message: 'Appointment created successfully',
        status: appointment.status.name,
        appointment: appointment,
      );
    } on PostgrestException catch (e) {
      debugPrint(
        '[app_create_appointment] ${e.message} (code: ${e.code}, details: ${e.details}, hint: ${e.hint})',
      );
      rethrow;
    }
  }

  /// Get all appointments for a user by email
  Future<List<Appointment>> getMyAppointments(String email) async {
    try {
      debugPrint('========== SUPABASE RPC ==========');
      debugPrint('Function: app_get_my_appointments');
      debugPrint('Param: p_email=$email');
      debugPrint('==================================\n');

      final dynamic response = await Supabase.instance.client.rpc(
        'app_get_my_appointments',
        params: {'p_email': email},
      );

      if (response is List) {
        return response
            .map((json) => Appointment.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
      }

      return [];
    } on PostgrestException catch (e) {
      throw Exception(e.message);
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
      final startTime = DateTime.parse('${newDate}T${newTime.padLeft(5, '0')}:00');
      final endTime = startTime.add(const Duration(minutes: 30));

      debugPrint('========== SUPABASE RPC ==========');
      debugPrint('Function: app_update_appointment');
      debugPrint('==================================\n');

      final dynamic raw = await Supabase.instance.client.rpc(
        'app_update_appointment',
        params: {
          'p_appointment_id': appointmentId,
          // Always send UTC to preserve the exact intended local slot.
          'p_appointment_start_time': startTime.toUtc().toIso8601String(),
          'p_appointment_end_time': endTime.toUtc().toIso8601String(),
          'p_appointment_time': newTime,
        },
      );

      final rows = raw as List<dynamic>;
      if (rows.isEmpty) {
        throw Exception('No appointment returned from update RPC.');
      }
      return Appointment.fromJson(Map<String, dynamic>.from(rows.first as Map));
    } on PostgrestException {
      rethrow;
    }
  }

  /// Cancel an appointment
  Future<AppointmentResponse> cancelAppointment(int appointmentId) async {
    try {
      await Supabase.instance.client.rpc(
        'app_set_appointment_status',
        params: {
          'p_appointment_id': appointmentId,
          'p_status': 'CANCELLED',
        },
      );
      return AppointmentResponse(message: 'Appointment cancelled', status: 'CANCELLED');
    } on PostgrestException {
      rethrow;
    }
  }

  /// Confirm an appointment
  Future<AppointmentResponse> confirmAppointment(int appointmentId) async {
    try {
      await Supabase.instance.client.rpc(
        'app_set_appointment_status',
        params: {
          'p_appointment_id': appointmentId,
          'p_status': 'CONFIRMED',
        },
      );
      return AppointmentResponse(message: 'Appointment confirmed', status: 'CONFIRMED');
    } on PostgrestException {
      rethrow;
    }
  }

  /// Add/Update notes to an appointment (uses PUT for both add and update)
  Future<AppointmentNoteResponse> addAppointmentNotes({
    required int appointmentId,
    required String noteType,
    required String clinicalNotes,
    required String diagnosis,
    required String treatmentPlan,
    required String observations,
  }) async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('User is not authenticated');
      }
      await Supabase.instance.client.from('appointment_notes').insert({
        'appointment_id': appointmentId,
        'author_id': uid,
        'note_type': noteType,
        'clinical_notes': clinicalNotes,
        'diagnosis': diagnosis,
        'treatment_plan': treatmentPlan,
        'observations': observations,
      });

      return AppointmentNoteResponse(
        message: 'Appointment note saved successfully',
        status: 'COMPLETED',
      );
    } on PostgrestException {
      rethrow;
    }
  }

  /// Get appointment notes by appointmentId
  Future<List<AppointmentNote>> getAppointmentNotesByAppointmentId(int appointmentId) async {
    try {
      final List<dynamic> rows = await Supabase.instance.client
          .from('appointment_notes')
          .select(
              'id, note_type, clinical_notes, diagnosis, treatment_plan, observations, created_at')
          .eq('appointment_id', appointmentId)
          .order('created_at', ascending: false);

      return rows.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return AppointmentNote.fromJson({
          'id': map['id'],
          'noteType': map['note_type'],
          'clinicalNotes': map['clinical_notes'],
          'diagnosis': map['diagnosis'],
          'treatmentPlan': map['treatment_plan'],
          'observations': map['observations'],
          'createdAt': map['created_at'],
        });
      }).toList();
    } on PostgrestException {
      rethrow;
    }
  }

  /// Get specific appointment note by appointmentId and noteId
  Future<AppointmentNote> getAppointmentNoteById({
    required int appointmentId,
    required int noteId,
  }) async {
    try {
      final dynamic row = await Supabase.instance.client
          .from('appointment_notes')
          .select(
              'id, note_type, clinical_notes, diagnosis, treatment_plan, observations, created_at')
          .eq('appointment_id', appointmentId)
          .eq('id', noteId)
          .maybeSingle();

      if (row == null) {
        throw Exception('Appointment note not found');
      }

      final map = Map<String, dynamic>.from(row as Map);
      return AppointmentNote.fromJson({
        'id': map['id'],
        'noteType': map['note_type'],
        'clinicalNotes': map['clinical_notes'],
        'diagnosis': map['diagnosis'],
        'treatmentPlan': map['treatment_plan'],
        'observations': map['observations'],
        'createdAt': map['created_at'],
      });
    } on PostgrestException {
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
      await Supabase.instance.client
          .from('appointment_notes')
          .update({
            'note_type': noteType,
            'clinical_notes': clinicalNotes,
            'diagnosis': diagnosis,
            'treatment_plan': treatmentPlan,
            'observations': observations,
          })
          .eq('appointment_id', appointmentId)
          .eq('id', noteId);

      return AppointmentNoteResponse(
        message: 'Appointment note updated successfully',
        status: 'COMPLETED',
      );
    } on PostgrestException {
      rethrow;
    }
  }

  /// Delete an appointment note
  Future<AppointmentNoteResponse> deleteAppointmentNote({
    required int appointmentId,
    required int noteId,
  }) async {
    try {
      await Supabase.instance.client
          .from('appointment_notes')
          .delete()
          .eq('appointment_id', appointmentId)
          .eq('id', noteId);

      return AppointmentNoteResponse(
        message: 'Appointment note deleted successfully',
        status: 'COMPLETED',
      );
    } on PostgrestException {
      rethrow;
    }
  }

  /// Start video call for an appointment
  Future<VideoStartResponse> startVideo({
    required int appointmentId,
  }) async {
    debugPrint('[AppointmentApi] startVideo called (appointmentId=$appointmentId)');
    return _fetchAgoraToken(
      appointmentId: appointmentId,
      persistSession: true,
    );
  }

  /// Refresh Agora token without creating a new video session row.
  Future<VideoStartResponse> refreshVideoToken({
    required int appointmentId,
  }) async {
    debugPrint('[AppointmentApi] refreshVideoToken called (appointmentId=$appointmentId)');
    return _fetchAgoraToken(
      appointmentId: appointmentId,
      persistSession: false,
    );
  }

  Future<VideoStartResponse> _fetchAgoraToken({
    required int appointmentId,
    required bool persistSession,
  }) async {
    try {
      debugPrint('[AppointmentApi] _fetchAgoraToken invoking app-agora-token (appointmentId=$appointmentId, persistSession=$persistSession)');
      final functionResponse = await Supabase.instance.client.functions.invoke(
        'app-agora-token',
        body: {'appointment_id': appointmentId},
      );

      final responseData = functionResponse.data;
      debugPrint('[AppointmentApi] _fetchAgoraToken raw response type=${responseData.runtimeType}');
      if (responseData is! Map) {
        throw Exception('Invalid token response from app-agora-token.');
      }
      final parsed = VideoStartResponse.fromJson(Map<String, dynamic>.from(responseData));
      debugPrint('[AppointmentApi] _fetchAgoraToken parsed (room=${parsed.roomName}, uid=${parsed.uid}, expiresAt=${parsed.expiresAt})');

      if (persistSession) {
        // Persist metadata for traceability/debugging in appointment history.
        debugPrint('[AppointmentApi] _fetchAgoraToken inserting appointment_video_sessions row');
        await Supabase.instance.client.from('appointment_video_sessions').insert({
          'appointment_id': appointmentId,
          'room_name': parsed.roomName,
          'access_token': null,
        });
      }

      debugPrint('[AppointmentApi] _fetchAgoraToken success');
      return parsed;
    } on PostgrestException {
      debugPrint('[AppointmentApi] _fetchAgoraToken PostgrestException');
      rethrow;
    } on FunctionException catch (e) {
      debugPrint('[AppointmentApi] _fetchAgoraToken FunctionException: ${e.details ?? e.reasonPhrase}');
      throw Exception(e.details ?? e.reasonPhrase ?? 'Unable to generate Agora token.');
    }
  }

  /// End video call for an appointment
  Future<VideoEndResponse> endVideo({
    required int appointmentId,
  }) async {
    try {
      debugPrint('[AppointmentApi] endVideo called (appointmentId=$appointmentId)');
      await Supabase.instance.client
          .from('appointment_video_sessions')
          .update({
            'ended_at': DateTime.now().toIso8601String(),
            'ended_ok': true,
          })
          .eq('appointment_id', appointmentId)
          .isFilter('ended_at', null);

      debugPrint('[AppointmentApi] endVideo session marked ended');
      return VideoEndResponse(
        appointmentId: appointmentId,
        status: true,
      );
    } on PostgrestException {
      debugPrint('[AppointmentApi] endVideo PostgrestException');
      rethrow;
    }
  }

  /// Public avatar URL for [email] from [profiles.profile_pic_url], if readable under RLS.
  Future<String?> fetchProfilePicUrlForEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || trimmed == '—') return null;
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('profile_pic_url')
          .ilike('email', trimmed)
          .maybeSingle();
      final url = row?['profile_pic_url'] as String?;
      if (url == null || url.trim().isEmpty) return null;
      return url.trim();
    } catch (e) {
      debugPrint('[AppointmentApi] fetchProfilePicUrlForEmail: $e');
      return null;
    }
  }
}



