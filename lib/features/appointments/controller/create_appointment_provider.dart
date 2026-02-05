import 'package:flutter/material.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/core/utils/shared_preferences_service.dart';
import 'package:telehealth_app/features/appointments/services/appointment_api.dart';
import '../model/appointment_model.dart';

class CreateAppointmentProvider extends ChangeNotifier {
  final AppointmentApi _appointmentApi = AppointmentApi();

  // Controllers
  final doctorEmailController = TextEditingController();
  final patientEmailController = TextEditingController();
  final descriptionController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();

  // State
  bool isLoading = false;
  String? error;
  String? userEmail;
  String? userRole;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  Appointment? createdAppointment;

  CreateAppointmentProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    userEmail = await SharedPreferencesService.getEmail();
    userRole = await SharedPreferencesService.getRole();
    
    // Pre-fill patient email if user is a patient
    if (userRole == 'PATIENT' && userEmail != null) {
      patientEmailController.text = userEmail!;
    }
    
    // Pre-fill doctor email if user is a doctor
    if (userRole == 'DOCTOR' && userEmail != null) {
      doctorEmailController.text = userEmail!;
    }
    
    notifyListeners();
  }

  /// Validate that appointment date is within 14 days
  bool isDateWithin14Days(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    final difference = selected.difference(today).inDays;
    
    return difference >= 0 && difference <= 14;
  }

  /// Get minimum selectable date (today)
  DateTime get minDate => DateTime.now();

  /// Get maximum selectable date (14 days from now)
  DateTime get maxDate => DateTime.now().add(const Duration(days: 14));

  /// Select date for appointment
  Future<void> selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: minDate,
      lastDate: maxDate,
      helpText: 'Select Appointment Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF6CA6FF),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      selectedDate = pickedDate;
      dateController.text = _formatDateForInput(pickedDate);
      notifyListeners();
    }
  }

  /// Select time for appointment
  Future<void> selectTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      helpText: 'Select Appointment Time',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF6CA6FF),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      selectedTime = pickedTime;
      timeController.text = _formatTimeForInput(pickedTime);
      notifyListeners();
    }
  }

  /// Format date for input field (DD-MM-YYYY)
  String _formatDateForInput(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  /// Format time for input field (HH:MM)
  String _formatTimeForInput(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Convert date and time to ISO format for API
  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Validate form
  bool get isFormValid {
    return doctorEmailController.text.trim().isNotEmpty &&
        patientEmailController.text.trim().isNotEmpty &&
        descriptionController.text.trim().isNotEmpty &&
        selectedDate != null &&
        selectedTime != null &&
        isDateWithin14Days(selectedDate!);
  }

  /// Get validation error message
  String? get validationError {
    if (doctorEmailController.text.trim().isEmpty) {
      return 'Doctor email is required';
    }
    if (patientEmailController.text.trim().isEmpty) {
      return 'Patient email is required';
    }
    if (descriptionController.text.trim().isEmpty) {
      return 'Description is required';
    }
    if (selectedDate == null) {
      return 'Please select a date';
    }
    if (selectedTime == null) {
      return 'Please select a time';
    }
    if (!isDateWithin14Days(selectedDate!)) {
      return 'Appointment must be within 14 days from today';
    }
    return null;
  }

  /// Create appointment
  Future<bool> createAppointment() async {
    if (!isFormValid) {
      error = validationError ?? 'Please fill all required fields';
      notifyListeners();
      return false;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final date = selectedDate!;
      final time = selectedTime!;
      
      // Create start and end times (assuming 30 minutes duration)
      final startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      final endDateTime = startDateTime.add(const Duration(minutes: 30));

      final response = await _appointmentApi.createAppointment(
        doctorEmail: doctorEmailController.text.trim(),
        patientEmail: patientEmailController.text.trim(),
        shortDescription: descriptionController.text.trim(),
        date: _formatDateForApi(date),
        time: _formatTimeForInput(time),
        appointmentStartTime: startDateTime.toIso8601String(),
        appointmentEndTime: endDateTime.toIso8601String(),
      );

      if (response.appointment != null) {
        createdAppointment = response.appointment;
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = response.message.isNotEmpty ? response.message : 'Failed to create appointment';
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
      error = 'Failed to create appointment. Please try again.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset form
  void reset() {
    doctorEmailController.clear();
    patientEmailController.clear();
    descriptionController.clear();
    dateController.clear();
    timeController.clear();
    selectedDate = null;
    selectedTime = null;
    createdAppointment = null;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    doctorEmailController.dispose();
    patientEmailController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }
}

