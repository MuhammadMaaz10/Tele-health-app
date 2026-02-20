import 'package:flutter/material.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
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
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _appointmentApi.startVideo(appointmentId: appointmentId);
      videoStartResponse = response;
      isVideoActive = true;
      isLoading = false;
      notifyListeners();
      return true;
    } on NetworkExceptions catch (e) {
      error = e.message;
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      error = 'Failed to start video call. Please try again.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// End video call for an appointment
  Future<bool> endVideo(int appointmentId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _appointmentApi.endVideo(appointmentId: appointmentId);
      if (response.status) {
        isVideoActive = false;
        videoStartResponse = null;
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = 'Failed to end video call';
        isLoading = false;
        notifyListeners();
        return false;
      }
    } on NetworkExceptions catch (e) {
      error = e.message;
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      error = 'Failed to end video call. Please try again.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    videoStartResponse = null;
    isVideoActive = false;
    error = null;
    notifyListeners();
  }
}

