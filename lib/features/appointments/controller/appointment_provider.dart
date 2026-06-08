import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:telehealth_app/core/utils/shared_preferences_service.dart';
import 'package:telehealth_app/features/appointments/services/appointment_api.dart';
import '../model/appointment_model.dart';

class AppointmentProvider extends ChangeNotifier {
  final AppointmentApi _appointmentApi = AppointmentApi();

  bool isLoading = false;
  bool isLoadingAppointments = false;
  String? error;
  List<Appointment> appointments = [];
  String? userEmail;
  String? userRole;
  AppointmentStatus? filterStatus;

  AppointmentProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    userEmail = await SharedPreferencesService.getEmail();
    userRole = await SharedPreferencesService.getRole();

    notifyListeners();

    if (userEmail != null) {
      await loadAppointments();
    }
  }

  /// Load all appointments for the current user
  Future<void> loadAppointments() async {
    if (userEmail == null) return;

    isLoadingAppointments = true;
    error = null;
    notifyListeners();

    try {
      appointments = await _appointmentApi.getMyAppointments(userEmail!);
      // Sort by creation date (latest first), then by start time (latest first)
      appointments.sort((a, b) {
        // First sort by createdAt (most recent first)
        final createdAtComparison = b.createdAt.compareTo(a.createdAt);
        if (createdAtComparison != 0) {
          return createdAtComparison;
        }
        // If createdAt is the same, sort by startTime (most recent first)
        return b.startTime.compareTo(a.startTime);
      });
      notifyListeners();
    } on PostgrestException catch (e) {
      error = e.message;
      appointments = [];
      notifyListeners();
    } catch (e) {
      error = 'Failed to load appointments. Please try again.';
      appointments = [];
      notifyListeners();
    } finally {
      isLoadingAppointments = false;
      notifyListeners();
    }
  }

  /// Filter appointments by status
  void filterByStatus(AppointmentStatus? status) {
    filterStatus = status;
    notifyListeners();
  }

  /// Get filtered appointments based on current filter
  List<Appointment> get filteredAppointments {
    if (filterStatus == null) return appointments;
    return appointments.where((appointment) => appointment.status == filterStatus).toList();
  }

  /// Get upcoming appointments
  /// For doctors: includes confirmed or rescheduled appointments that are in the future
  /// For others: includes all upcoming appointments
  List<Appointment> get upcomingAppointments {
    if (userRole == 'DOCTOR' || userRole == 'NURSE') {
      // For doctors/nurses, show confirmed or rescheduled appointments that are in the future
      return appointments.where((appointment) => 
        appointment.isUpcoming && 
        (appointment.status == AppointmentStatus.CONFIRMED || 
         appointment.status == AppointmentStatus.RESCHEDULED)
      ).toList();
    }
    // For patients, show all upcoming appointments
    return appointments.where((appointment) => appointment.isUpcoming).toList();
  }

  /// Get past appointments
  List<Appointment> get pastAppointments {
    return appointments.where((appointment) => appointment.isPast).toList();
  }

  /// Get appointments by status
  List<Appointment> getAppointmentsByStatus(AppointmentStatus status) {
    return appointments.where((appointment) => appointment.status == status).toList();
  }

  /// Cancel an appointment
  Future<bool> cancelAppointment(int appointmentId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _appointmentApi.cancelAppointment(appointmentId);
      
      // Reload appointments to get updated status
      await loadAppointments();
      
      isLoading = false;
      notifyListeners();
      return response.status == 'CANCELLED';
    } on PostgrestException catch (e) {
      error = e.message;
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      error = 'Failed to cancel appointment. Please try again.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Confirm an appointment
  Future<bool> confirmAppointment(int appointmentId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _appointmentApi.confirmAppointment(appointmentId);
      
      // Reload appointments to get updated status
      await loadAppointments();
      
      isLoading = false;
      notifyListeners();
      return response.status == 'CONFIRMED';
    } on PostgrestException catch (e) {
      error = e.message;
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      error = 'Failed to confirm appointment. Please try again.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update/Reschedule an appointment
  Future<bool> updateAppointment({
    required int appointmentId,
    required String doctorEmail,
    required String patientEmail,
    required String newDate,
    required String newTime,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _appointmentApi.updateAppointment(
        appointmentId: appointmentId,
        doctorEmail: doctorEmail,
        patientEmail: patientEmail,
        newDate: newDate,
        newTime: newTime,
      );
      
      // Reload appointments to get updated data
      await loadAppointments();
      
      isLoading = false;
      notifyListeners();
      return true;
    } on PostgrestException catch (e) {
      error = e.message;
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      error = 'Failed to update appointment. Please try again.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get appointment by ID
  Appointment? getAppointmentById(int id) {
    try {
      return appointments.firstWhere((appointment) => appointment.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}



