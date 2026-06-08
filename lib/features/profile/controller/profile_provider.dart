import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:telehealth_app/core/utils/location_utils.dart';
import 'package:telehealth_app/core/utils/shared_preferences_service.dart';
import '../model/profile_model.dart' as pm;

class ProfileProvider extends ChangeNotifier {
  
  bool isLoading = false;
  bool isLoadingProfile = false;
  String? error;
  pm.ProfileModel? profileModel;
  pm.User? user;
  String? userEmail;
  String? userRole;

  ProfileProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    userEmail = await SharedPreferencesService.getEmail();
    userEmail ??= Supabase.instance.client.auth.currentUser?.email;
    userRole = await SharedPreferencesService.getRole();

    notifyListeners();

    final session = Supabase.instance.client.auth.currentSession;
    if (userEmail != null || session != null) {
      await loadProfile();
    }
  }

  Future<void> loadProfile() async {
    if (Supabase.instance.client.auth.currentSession != null) {
      await _loadProfileFromSupabase();
      return;
    }
    if (userEmail == null) return;
    error = 'Sign in to load your profile.';
    notifyListeners();
  }

  Future<void> _loadProfileFromSupabase() async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return;

    isLoadingProfile = true;
    error = null;
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      final row =
          await client.from('profiles').select().eq('id', authUser.id).maybeSingle();

      if (row == null) {
        error = 'Profile not found.';
        isLoadingProfile = false;
        notifyListeners();
        return;
      }

      final rolesRes = await client
          .from('user_roles')
          .select('role_id, roles(name)')
          .eq('user_id', authUser.id);

      final List<pm.Role> roles = [];
      final rowsList = rolesRes as List<dynamic>;
      for (final raw in rowsList) {
        final map = Map<String, dynamic>.from(raw as Map);
        final nested = map['roles'];
        final name = nested is Map && nested['name'] != null
            ? nested['name'] as String
            : null;
        final rid = (map['role_id'] as num?)?.toInt() ?? 0;
        if (name != null) {
          roles.add(pm.Role(roleName: name, roleId: rid));
        }
      }

      userEmail = row['email'] as String? ?? authUser.email;
      if (userEmail != null) {
        await SharedPreferencesService.saveEmail(userEmail!);
      }
      userRole = roles.isNotEmpty ? roles.first.roleName : null;
      if (userRole != null) {
        await SharedPreferencesService.saveRole(userRole!);
      }

      pm.Location? loc;
      if (row['latitude'] != null && row['longitude'] != null) {
        loc = pm.Location(
          latitude: (row['latitude'] as num).toDouble(),
          longitude: (row['longitude'] as num).toDouble(),
        );
        try {
          final address = await LocationUtils.getAddressFromCoordinates(
            latitude: loc.latitude,
            longitude: loc.longitude,
          );
          loc.setReadableAddress(address);
        } catch (e) {
          debugPrint('Failed to reverse geocode location: $e');
        }
      }

      user = pm.User(
        id: 0,
        email: row['email'] as String? ?? '',
        phone: row['phone'] as String?,
        enabled: row['enabled'] as bool? ?? true,
        location: loc,
        createdAt: row['created_at']?.toString(),
        dob: row['dob']?.toString(),
        username: row['username'] as String?,
        idDocumentUrl: row['id_document_url'] as String?,
        medicalCertificateUrl: row['medical_certificate_url'] as String?,
        educationalCertificateUrl: row['educational_certificate_url'] as String?,
        specialization: row['specialization'] as String?,
        profilePicUrl: row['profile_pic_url'] as String?,
        gender: row['gender'] as String?,
        roles: roles,
      );

      profileModel = pm.ProfileModel(
        success: true,
        message: '',
        data: pm.ProfileData(
          email: userEmail ?? '',
          status: 'ACTIVE',
          message: '',
          user: user,
        ),
      );

      notifyListeners();
    } catch (e) {
      error = 'Failed to load profile. Please try again.';
      debugPrint('Supabase profile load: $e');
      notifyListeners();
    } finally {
      isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.signOut();
      await SharedPreferencesService.clearAuthData();
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

}

