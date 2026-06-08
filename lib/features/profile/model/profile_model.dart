/// Reads the first non-empty string from [map] using case-insensitive key matching.
/// Helps with Supabase/PostgREST rows where key casing or aliases may vary.
String? readLooseString(Map<String, dynamic> map, List<String> keyCandidates) {
  for (final wanted in keyCandidates) {
    final w = wanted.toLowerCase();
    for (final e in map.entries) {
      if (e.key.toLowerCase() == w) {
        final v = e.value;
        if (v == null) continue;
        final s = v is String ? v.trim() : v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
  }
  return null;
}

class ProfileModel {
  final bool success;
  final String message;
  final ProfileData? data;

  ProfileModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? ProfileData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ProfileData {
  final String email;
  final String status;
  final String message;
  final User? user;

  ProfileData({
    required this.email,
    required this.status,
    required this.message,
    this.user,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class User {
  final int id;
  final String email;
  final String? phone;
  final bool enabled;
  final Location? location;
  final String? createdAt;
  final String? dob;
  final String? username;
  final String? idDocumentUrl;
  final String? medicalCertificateUrl;
  final String? educationalCertificateUrl;
  final String? specialization;
  final String? profilePicUrl;
  final String? gender;
  final List<Role> roles;

  User({
    required this.id,
    required this.email,
    this.phone,
    required this.enabled,
    this.location,
    this.createdAt,
    this.dob,
    this.username,
    this.idDocumentUrl,
    this.medicalCertificateUrl,
    this.educationalCertificateUrl,
    this.specialization,
    this.profilePicUrl,
    this.gender,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      enabled: json['enabled'] as bool? ?? false,
      location: json['location'] != null
          ? Location.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] as String?,
      dob: json['dob'] as String?,
      username: json['username'] as String?,
      idDocumentUrl: json['idDocumentUrl'] as String?,
      medicalCertificateUrl: json['medicalCertificateUrl'] as String?,
      educationalCertificateUrl: json['educationalCertificateUrl'] as String?,
      specialization: json['specialization'] as String?,
      profilePicUrl: json['profilePicUrl'] as String?,
      gender: json['gender'] as String?,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((role) => Role.fromJson(role as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get primaryRole {
    if (roles.isEmpty) return 'USER';
    return roles.first.roleName;
  }

  /// Primary line in user pickers (e.g. appointment directory): name when present, else email.
  String get directoryListTitle {
    final n = username?.trim();
    if (n != null && n.isNotEmpty) return n;
    return email;
  }
}

class Location {
  final double latitude;
  final double longitude;
  String? _readableAddress; // Cache for reverse geocoded address

  Location({
    required this.latitude,
    required this.longitude,
    String? readableAddress,
  }) : _readableAddress = readableAddress;

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get formatted {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  /// Set the readable address (from reverse geocoding)
  void setReadableAddress(String address) {
    _readableAddress = address;
  }

  /// Get readable address if available, otherwise return coordinates
  String get readableAddress {
    return _readableAddress ?? formatted;
  }
}

class Role {
  final String roleName;
  final int roleId;

  Role({
    required this.roleName,
    required this.roleId,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      roleName: json['roleName'] as String? ?? '',
      roleId: json['roleId'] as int? ?? 0,
    );
  }
}

