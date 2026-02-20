import 'package:flutter/material.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/core/utils/shared_preferences_service.dart';
import 'package:telehealth_app/features/appointments/services/appointment_api.dart';
import '../model/appointment_note_model.dart';

class AppointmentNotesProvider extends ChangeNotifier {
  final AppointmentApi _appointmentApi = AppointmentApi();

  // Controllers
  final clinicalNotesController = TextEditingController();
  final diagnosisController = TextEditingController();
  final treatmentPlanController = TextEditingController();
  final observationsController = TextEditingController();

  // State
  bool isLoading = false;
  bool isLoadingNotes = false;
  String? error;
  List<AppointmentNote> notes = [];
  NoteType selectedNoteType = NoteType.SUBJECTIVE;
  String? userRole;
  int? editingNoteId; // Track which note is being edited

  AppointmentNotesProvider() {
    _loadRole();
  }

  Future<void> _loadRole() async {
    userRole = await SharedPreferencesService.getRole();
    notifyListeners();
  }

  /// Check if user can add/edit/delete notes (doctors and nurses only)
  bool get canModifyNotes {
    if (userRole == null) return false;
    final role = userRole!.toUpperCase().trim();
    return role == 'DOCTOR' || role == 'NURSE';
  }

  /// Check if user is a patient
  bool get isPatient {
    if (userRole == null) return false;
    final role = userRole!.toUpperCase().trim();
    return role == 'PATIENT';
  }

  int? _currentAppointmentId;
  AppointmentNote? _existingNote; // Track the existing note for the appointment

  /// Load appointment notes for a specific appointment
  Future<void> loadNotes({required int appointmentId}) async {
    isLoadingNotes = true;
    error = null;
    _currentAppointmentId = appointmentId;
    _existingNote = null;
    editingNoteId = null;
    notifyListeners();

    try {
      final appointmentNotes = await _appointmentApi.getAppointmentNotesByAppointmentId(appointmentId);
      
      notes = appointmentNotes;
      
      // Sort by creation date (newest first)
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // If a note exists and user is a doctor/nurse, automatically load it for editing
      if (notes.isNotEmpty && canModifyNotes) {
        _existingNote = notes.first; // Get the most recent note
        // Auto-load the note for editing
        loadNoteForEditing(_existingNote!);
      }
      
      notifyListeners();
    } on NetworkExceptions catch (e) {
      error = e.message;
      notes = [];
      notifyListeners();
    } catch (e) {
      error = 'Failed to load appointment notes. Please try again.';
      notes = [];
      notifyListeners();
    } finally {
      isLoadingNotes = false;
      notifyListeners();
    }
  }

  /// Load a specific appointment note by appointmentId and noteId
  Future<AppointmentNote?> loadNoteById({
    required int appointmentId,
    required int noteId,
  }) async {
    isLoadingNotes = true;
    error = null;
    notifyListeners();

    try {
      final note = await _appointmentApi.getAppointmentNoteById(
        appointmentId: appointmentId,
        noteId: noteId,
      );
      isLoadingNotes = false;
      notifyListeners();
      return note;
    } on NetworkExceptions catch (e) {
      error = e.message;
      isLoadingNotes = false;
      notifyListeners();
      return null;
    } catch (e) {
      error = 'Failed to load appointment note. Please try again.';
      isLoadingNotes = false;
      notifyListeners();
      return null;
    }
  }

  /// Set note type
  void setNoteType(NoteType type) {
    selectedNoteType = type;
    notifyListeners();
  }

  /// Load note data into form for editing
  void loadNoteForEditing(AppointmentNote note) {
    editingNoteId = note.id;
    clinicalNotesController.text = note.clinicalNotes;
    diagnosisController.text = note.diagnosis;
    treatmentPlanController.text = note.treatmentPlan;
    observationsController.text = note.observations;
    // Set note type if available
    if (note.noteType != null) {
      selectedNoteType = NoteType.fromString(note.noteType!);
    }
    notifyListeners();
  }

  /// Cancel editing and clear form
  void cancelEditing() {
    editingNoteId = null;
    reset();
  }

  /// Validate form
  bool get isFormValid {
    return clinicalNotesController.text.trim().isNotEmpty &&
        diagnosisController.text.trim().isNotEmpty &&
        treatmentPlanController.text.trim().isNotEmpty &&
        observationsController.text.trim().isNotEmpty;
  }

  /// Get validation error message
  String? get validationError {
    if (clinicalNotesController.text.trim().isEmpty) {
      return 'Clinical notes are required';
    }
    if (diagnosisController.text.trim().isEmpty) {
      return 'Diagnosis is required';
    }
    if (treatmentPlanController.text.trim().isEmpty) {
      return 'Treatment plan is required';
    }
    if (observationsController.text.trim().isEmpty) {
      return 'Observations are required';
    }
    return null;
  }

  /// Check if a note already exists for the appointment
  bool get hasExistingNote => _existingNote != null;

  /// Add notes to an appointment
  /// Note: This should only be called if no note exists yet
  Future<bool> addAppointmentNotes(int appointmentId) async {
    if (!canModifyNotes) {
      error = 'You do not have permission to add notes';
      notifyListeners();
      return false;
    }

    // Check if a note already exists - doctors can only add once, then update
    if (hasExistingNote) {
      error = 'A note already exists for this appointment. Please update the existing note instead.';
      notifyListeners();
      return false;
    }

    if (!isFormValid) {
      error = validationError ?? 'Please fill all required fields';
      notifyListeners();
      return false;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _appointmentApi.addAppointmentNotes(
        appointmentId: appointmentId,
        noteType: selectedNoteType.name,
        clinicalNotes: clinicalNotesController.text.trim(),
        diagnosis: diagnosisController.text.trim(),
        treatmentPlan: treatmentPlanController.text.trim(),
        observations: observationsController.text.trim(),
      );

      if (response.status == 'COMPLETED') {
        // Reload notes to get the new one (will auto-load for editing)
        await loadNotes(appointmentId: appointmentId);
        
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = response.message.isNotEmpty ? response.message : 'Failed to add notes';
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
      error = 'Failed to add appointment notes. Please try again.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing note
  Future<bool> updateAppointmentNote(int appointmentId, int noteId) async {
    if (!canModifyNotes) {
      error = 'You do not have permission to edit notes';
      notifyListeners();
      return false;
    }

    if (!isFormValid) {
      error = validationError ?? 'Please fill all required fields';
      notifyListeners();
      return false;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _appointmentApi.updateAppointmentNote(
        appointmentId: appointmentId,
        noteId: noteId,
        noteType: selectedNoteType.name,
        clinicalNotes: clinicalNotesController.text.trim(),
        diagnosis: diagnosisController.text.trim(),
        treatmentPlan: treatmentPlanController.text.trim(),
        observations: observationsController.text.trim(),
      );

      if (response.status == 'COMPLETED') {
        // Reload notes to get the updated one
        await loadNotes(appointmentId: appointmentId);
        
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = response.message.isNotEmpty ? response.message : 'Failed to update note';
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
      error = 'Failed to update appointment note. Please try again.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a note
  Future<bool> deleteAppointmentNote(int appointmentId, int noteId) async {
    if (!canModifyNotes) {
      error = 'You do not have permission to delete notes';
      notifyListeners();
      return false;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _appointmentApi.deleteAppointmentNote(
        appointmentId: appointmentId,
        noteId: noteId,
      );

      if (response.status == 'COMPLETED') {
        // Reload notes to remove the deleted one
        if (_currentAppointmentId != null) {
          await loadNotes(appointmentId: _currentAppointmentId!);
        }
        
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = response.message.isNotEmpty ? response.message : 'Failed to delete note';
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
      error = 'Failed to delete appointment note. Please try again.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get note by ID
  AppointmentNote? getNoteById(int id) {
    try {
      return notes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Reset form
  void reset() {
    clinicalNotesController.clear();
    diagnosisController.clear();
    treatmentPlanController.clear();
    observationsController.clear();
    selectedNoteType = NoteType.SUBJECTIVE;
    editingNoteId = null;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clinicalNotesController.dispose();
    diagnosisController.dispose();
    treatmentPlanController.dispose();
    observationsController.dispose();
    super.dispose();
  }
}



