import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:telehealth_app/core/utils/shared_preferences_service.dart';

/// Keeps SharedPreferences in sync with Supabase Auth session data.
class SupabaseSessionSync {
  SupabaseSessionSync._();

  static Future<void> applySession(Session? session) async {
    if (session == null) {
      await SharedPreferencesService.clearAuthData();
      return;
    }

    final token = session.accessToken;
    await SharedPreferencesService.saveToken(token);

    final email = session.user.email;
    if (email != null && email.isNotEmpty) {
      await SharedPreferencesService.saveEmail(email);
    }

    final role = await fetchPrimaryRoleName(session.user.id);
    if (role != null && role.isNotEmpty) {
      await SharedPreferencesService.saveRole(role);
    }
  }

  /// First role name from [user_roles] → [roles], if present.
  static Future<String?> fetchPrimaryRoleName(String userId) async {
    try {
      final rows = await Supabase.instance.client
          .from('user_roles')
          .select('role_id, roles(name)')
          .eq('user_id', userId);

      final list = rows as List<dynamic>;
      if (list.isEmpty) return null;

      final first = Map<String, dynamic>.from(list.first as Map);
      final roles = first['roles'];
      if (roles is Map && roles['name'] != null) {
        return roles['name'] as String;
      }
    } catch (_) {
      // Table missing or RLS — non-fatal for login
    }
    return null;
  }
}
