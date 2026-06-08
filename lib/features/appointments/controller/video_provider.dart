import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:telehealth_app/features/appointments/services/appointment_api.dart';
import '../model/appointment_note_model.dart';

class VideoProvider extends ChangeNotifier {
  final AppointmentApi _appointmentApi = AppointmentApi();

  // State
  bool isLoading = false;
  String? error;
  VideoStartResponse? videoStartResponse;
  bool isVideoActive = false;

  /// Start video call for an appointment
  Future<bool> startVideo(int appointmentId) async {
    debugPrint('[VideoProvider] startVideo called (appointmentId=$appointmentId)');
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _appointmentApi.startVideo(appointmentId: appointmentId);
      debugPrint('[VideoProvider] startVideo token response received (room=${response.roomName}, uid=${response.uid})');
      if (response.appId.isEmpty || response.accessToken.isEmpty || response.roomName.isEmpty) {
        throw Exception('Incomplete Agora configuration from backend.');
      }
      videoStartResponse = response;
      isVideoActive = true;
      isLoading = false;
      notifyListeners();
      debugPrint('[VideoProvider] startVideo success');
      return true;
    } on PostgrestException catch (e) {
      debugPrint('[VideoProvider] startVideo PostgrestException: ${e.message}');
      error = e.message;
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[VideoProvider] startVideo error: $e');
      error = e.toString().replaceFirst('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// End video call for an appointment
  Future<bool> endVideo(int appointmentId) async {
    debugPrint('[VideoProvider] endVideo called (appointmentId=$appointmentId)');
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _appointmentApi.endVideo(appointmentId: appointmentId);
      debugPrint('[VideoProvider] endVideo API response status=${response.status}');
      if (response.status) {
        isVideoActive = false;
        videoStartResponse = null;
        isLoading = false;
        notifyListeners();
        debugPrint('[VideoProvider] endVideo success');
        return true;
      } else {
        error = 'Failed to end video call';
        isLoading = false;
        notifyListeners();
        return false;
      }
    } on PostgrestException catch (e) {
      debugPrint('[VideoProvider] endVideo PostgrestException: ${e.message}');
      error = e.message;
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[VideoProvider] endVideo error: $e');
      error = 'Failed to end video call. Please try again.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    debugPrint('[VideoProvider] reset called');
    videoStartResponse = null;
    isVideoActive = false;
    error = null;
    notifyListeners();
  }
}

