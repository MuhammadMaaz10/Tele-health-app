enum AppointmentStatus {
  PENDING,
  CONFIRMED,
  RESCHEDULED,
  CANCELLED,
  COMPLETED;

  static AppointmentStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AppointmentStatus.PENDING;
      case 'CONFIRMED':
        return AppointmentStatus.CONFIRMED;
      case 'RESCHEDULED':
        return AppointmentStatus.RESCHEDULED;
      case 'CANCELLED':
        return AppointmentStatus.CANCELLED;
      case 'COMPLETED':
        return AppointmentStatus.COMPLETED;
      default:
        return AppointmentStatus.PENDING;
    }
  }

  String get displayName {
    switch (this) {
      case AppointmentStatus.PENDING:
        return 'Pending';
      case AppointmentStatus.CONFIRMED:
        return 'Confirmed';
      case AppointmentStatus.RESCHEDULED:
        return 'Rescheduled';
      case AppointmentStatus.CANCELLED:
        return 'Cancelled';
      case AppointmentStatus.COMPLETED:
        return 'Completed';
    }
  }
}

class Appointment {
  final int id;
  final String doctorAssigned;
  final String patientBooked;
  final DateTime startTime;
  final DateTime endTime;
  final String description;
  final AppointmentStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String appointmentTime;
  final bool rescheduled;

  Appointment({
    required this.id,
    required this.doctorAssigned,
    required this.patientBooked,
    required this.startTime,
    required this.endTime,
    required this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.appointmentTime,
    required this.rescheduled,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final startTimeParsed = _parseDateTime(json['startTime'] as String?);
    final endTimeParsed = _parseDateTime(json['endTime'] as String?);
    final createdAtParsed = _parseDateTime(json['createdAt'] as String?);

    return Appointment(
      id: json['id'] as int? ?? 0,
      doctorAssigned: json['doctorAssigned'] as String? ?? '',
      patientBooked: json['patientBooked'] as String? ?? '',
      startTime: startTimeParsed ?? DateTime.now(),
      endTime: endTimeParsed ?? DateTime.now().add(const Duration(hours: 1)),
      description: json['description'] as String? ?? '',
      status: AppointmentStatus.fromString(json['status'] as String? ?? 'PENDING'),
      createdAt: createdAtParsed ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? _parseDateTime(json['updatedAt'] as String?)
          : null,
      appointmentTime: json['appointmentTime'] as String? ?? '',
      rescheduled: json['rescheduled'] as bool? ?? false,
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
      'doctorAssigned': doctorAssigned,
      'patientBooked': patientBooked,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'description': description,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'appointmentTime': appointmentTime,
      'rescheduled': rescheduled,
    };
  }

  String get formattedDate {
    final date = startTime;
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String get formattedTime {
    final time = startTime;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDateTime {
    return '$formattedDate at $formattedTime';
  }

  bool get isUpcoming {
    return startTime.isAfter(DateTime.now());
  }

  bool get isPast {
    return endTime.isBefore(DateTime.now());
  }

  Duration get duration {
    return endTime.difference(startTime);
  }
}

class CreateAppointmentRequest {
  final String doctorEmail;
  final String patientEmail;
  final String shortDescription;
  final String date;
  final String time;
  final String appointmentStartTime;
  final String appointmentEndTime;

  CreateAppointmentRequest({
    required this.doctorEmail,
    required this.patientEmail,
    required this.shortDescription,
    required this.date,
    required this.time,
    required this.appointmentStartTime,
    required this.appointmentEndTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'doctorEmail': doctorEmail,
      'patientEmail': patientEmail,
      'shortDescription': shortDescription,
      'date': date,
      'time': time,
      'appointmentStartTime': appointmentStartTime,
      'appointmentEndTime': appointmentEndTime,
    };
  }
}

class UpdateAppointmentRequest {
  final String doctorEmail;
  final String patientEmail;
  final String newDate;
  final String newTime;

  UpdateAppointmentRequest({
    required this.doctorEmail,
    required this.patientEmail,
    required this.newDate,
    required this.newTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'doctorEmail': doctorEmail,
      'patientEmail': patientEmail,
      'newDate': newDate,
      'newTime': newTime,
    };
  }
}

class AppointmentResponse {
  final String message;
  final String status;
  final Appointment? appointment;

  AppointmentResponse({
    required this.message,
    required this.status,
    this.appointment,
  });

  factory AppointmentResponse.fromJson(Map<String, dynamic> json) {
    return AppointmentResponse(
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? '',
      appointment: json['appointment'] != null
          ? Appointment.fromJson(json['appointment'] as Map<String, dynamic>)
          : null,
    );
  }
}

