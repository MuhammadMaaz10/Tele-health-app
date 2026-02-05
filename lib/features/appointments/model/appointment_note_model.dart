enum NoteType {
  GENERAL,
  FOLLOW_UP,
  EMERGENCY,
  ROUTINE;

  static NoteType fromString(String type) {
    switch (type.toUpperCase()) {
      case 'GENERAL':
        return NoteType.GENERAL;
      case 'FOLLOW_UP':
        return NoteType.FOLLOW_UP;
      case 'EMERGENCY':
        return NoteType.EMERGENCY;
      case 'ROUTINE':
        return NoteType.ROUTINE;
      default:
        return NoteType.GENERAL;
    }
  }

  String get displayName {
    switch (this) {
      case NoteType.GENERAL:
        return 'General';
      case NoteType.FOLLOW_UP:
        return 'Follow Up';
      case NoteType.EMERGENCY:
        return 'Emergency';
      case NoteType.ROUTINE:
        return 'Routine';
    }
  }
}

class AppointmentNote {
  final int id;
  final String clinicalNotes;
  final String diagnosis;
  final String treatmentPlan;
  final String observations;
  final DateTime createdAt;

  AppointmentNote({
    required this.id,
    required this.clinicalNotes,
    required this.diagnosis,
    required this.treatmentPlan,
    required this.observations,
    required this.createdAt,
  });

  factory AppointmentNote.fromJson(Map<String, dynamic> json) {
    return AppointmentNote(
      id: json['id'] as int? ?? 0,
      clinicalNotes: json['clinicalNotes'] as String? ?? '',
      diagnosis: json['diagnosis'] as String? ?? '',
      treatmentPlan: json['treatmentPlan'] as String? ?? '',
      observations: json['observations'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt'] as String?) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinicalNotes': clinicalNotes,
      'diagnosis': diagnosis,
      'treatmentPlan': treatmentPlan,
      'observations': observations,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get formattedDate {
    final date = createdAt;
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String get formattedTime {
    final time = createdAt;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDateTime {
    return '$formattedDate at $formattedTime';
  }
}

class CreateAppointmentNoteRequest {
  final String noteType;
  final String clinicalNotes;
  final String diagnosis;
  final String treatmentPlan;
  final String observations;

  CreateAppointmentNoteRequest({
    required this.noteType,
    required this.clinicalNotes,
    required this.diagnosis,
    required this.treatmentPlan,
    required this.observations,
  });

  Map<String, dynamic> toJson() {
    return {
      'noteType': noteType,
      'clinicalNotes': clinicalNotes,
      'diagnosis': diagnosis,
      'treatmentPlan': treatmentPlan,
      'observations': observations,
    };
  }
}

class AppointmentNoteResponse {
  final String message;
  final String status;

  AppointmentNoteResponse({
    required this.message,
    required this.status,
  });

  factory AppointmentNoteResponse.fromJson(Map<String, dynamic> json) {
    return AppointmentNoteResponse(
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}



