enum NoteType {
  SUBJECTIVE,
  OBJECTIVE,
  ASSESSMENT,
  PLAN,
  GENERAL,
  FOLLOW_UP,
  EMERGENCY,
  ROUTINE;

  static NoteType fromString(String type) {
    switch (type.toUpperCase()) {
      case 'SUBJECTIVE':
        return NoteType.SUBJECTIVE;
      case 'OBJECTIVE':
        return NoteType.OBJECTIVE;
      case 'ASSESSMENT':
        return NoteType.ASSESSMENT;
      case 'PLAN':
        return NoteType.PLAN;
      case 'GENERAL':
        return NoteType.GENERAL;
      case 'FOLLOW_UP':
      case 'FOLLOWUP':
        return NoteType.FOLLOW_UP;
      case 'EMERGENCY':
        return NoteType.EMERGENCY;
      case 'ROUTINE':
        return NoteType.ROUTINE;
      default:
        return NoteType.SUBJECTIVE; // Default to SUBJECTIVE as per backend
    }
  }

  String get displayName {
    switch (this) {
      case NoteType.SUBJECTIVE:
        return 'Subjective';
      case NoteType.OBJECTIVE:
        return 'Objective';
      case NoteType.ASSESSMENT:
        return 'Assessment';
      case NoteType.PLAN:
        return 'Plan';
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
  final String? noteType;
  final String clinicalNotes;
  final String diagnosis;
  final String treatmentPlan;
  final String observations;
  final DateTime createdAt;

  AppointmentNote({
    required this.id,
    this.noteType,
    required this.clinicalNotes,
    required this.diagnosis,
    required this.treatmentPlan,
    required this.observations,
    required this.createdAt,
  });

  factory AppointmentNote.fromJson(Map<String, dynamic> json) {
    return AppointmentNote(
      id: json['id'] as int? ?? 0,
      noteType: json['noteType'] as String?,
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
      'noteType': noteType,
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

class VideoStartResponse {
  final String roomName;
  final String accessToken;
  final String appId;
  final int uid;
  final DateTime? expiresAt;

  VideoStartResponse({
    required this.roomName,
    required this.accessToken,
    required this.appId,
    required this.uid,
    this.expiresAt,
  });

  factory VideoStartResponse.fromJson(Map<String, dynamic> json) {
    DateTime? parsedExpiry;
    final expiry = json['expiresAt'] ?? json['expires_at'];
    if (expiry is String && expiry.isNotEmpty) {
      parsedExpiry = DateTime.tryParse(expiry);
    }

    return VideoStartResponse(
      roomName: (json['roomName'] ?? json['room_name']) as String? ?? '',
      accessToken: (json['accessToken'] ?? json['access_token']) as String? ?? '',
      appId: (json['appId'] ?? json['app_id']) as String? ?? '',
      uid: (json['uid'] as num?)?.toInt() ?? 0,
      expiresAt: parsedExpiry,
    );
  }
}

class VideoEndResponse {
  final int appointmentId;
  final bool status;

  VideoEndResponse({
    required this.appointmentId,
    required this.status,
  });

  factory VideoEndResponse.fromJson(Map<String, dynamic> json) {
    return VideoEndResponse(
      appointmentId: json['appointmentId'] as int? ?? 0,
      status: json['status'] as bool? ?? false,
    );
  }
}



