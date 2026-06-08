import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, Supabase;
import 'package:telehealth_app/features/profile/model/profile_model.dart';

class UsersApi {
  /// Get all doctors
  Future<List<User>> getDoctors() async {
    try {
      final raw = await Supabase.instance.client.rpc('app_get_doctors_directory');
      return _mapUsers(raw);
    } on PostgrestException {
      rethrow;
    }
  }

  /// Get all patients
  Future<List<User>> getPatients() async {
    try {
      final raw = await Supabase.instance.client.rpc('app_get_patients_directory');
      return _mapUsers(raw);
    } on PostgrestException {
      rethrow;
    }
  }

  /// Get all nurses
  Future<List<User>> getNurses() async {
    try {
      final raw = await Supabase.instance.client.rpc('app_get_nurses_directory');
      return _mapUsers(raw);
    } on PostgrestException {
      rethrow;
    }
  }

  List<User> _mapUsers(dynamic raw) {
    if (raw is! List) return const <User>[];
    return raw.map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      return User(
        id: 0,
        email: readLooseString(map, ['email']) ?? '',
        username: readLooseString(map, [
          'username',
          'user_name',
          'name',
          'full_name',
          'fullname',
          'display_name',
          'displayname',
        ]),
        enabled: (map['enabled'] as bool?) ?? true,
        roles: const [],
      );
    }).toList();
  }
}










