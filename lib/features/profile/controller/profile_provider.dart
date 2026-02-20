import 'package:flutter/material.dart';
import 'package:telehealth_app/core/network/api_factory.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/core/utils/location_utils.dart';
import 'package:telehealth_app/core/utils/shared_preferences_service.dart';
import 'package:telehealth_app/features/auth/services/auth_api.dart';
import '../model/profile_model.dart';

class ProfileProvider extends ChangeNotifier {
  final AuthApi _authApi = AuthApi();
  
  bool isLoading = false;
  bool isLoadingProfile = false;
  String? error;
  ProfileModel? profileModel;
  User? user;
  String? userEmail;
  String? userRole;

  ProfileProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    userEmail = await SharedPreferencesService.getEmail();
    userRole = await SharedPreferencesService.getRole();
    
    // Re-initialize token on provider init (important for web/desktop reload)
    final token = await SharedPreferencesService.getToken();
    if (token != null && token.isNotEmpty) {
      ApiFactory.setAuthToken(token);
    }
    
    notifyListeners();
    
    if (userEmail != null) {
      await loadProfile();
    }
  }

  Future<void> loadProfile() async {
    if (userEmail == null) return;
    
    isLoadingProfile = true;
    error = null;
    notifyListeners();

    try {
      final response = await _authApi.getProfile(email: userEmail!);
      profileModel = ProfileModel.fromJson(response);
      user = profileModel?.data?.user;
      
      // Update role from API response if available
      if (user != null && user!.roles.isNotEmpty) {
        userRole = user!.primaryRole;
        await SharedPreferencesService.saveRole(userRole!);
      }
      
      // Reverse geocode location if available
      if (user != null && user!.location != null) {
        try {
          final address = await LocationUtils.getAddressFromCoordinates(
            latitude: user!.location!.latitude,
            longitude: user!.location!.longitude,
          );
          user!.location!.setReadableAddress(address);
        } catch (e) {
          // If reverse geocoding fails, location will use coordinates as fallback
          debugPrint('Failed to reverse geocode location: $e');
        }
      }
      
      notifyListeners();
    } on NetworkExceptions catch (e) {
      error = e.message;
      notifyListeners();
    } catch (e) {
      error = 'Failed to load profile. Please try again.';
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
      // Clear SharedPreferences
      await SharedPreferencesService.clearAuthData();
      
      // Clear API token
      ApiFactory.clearAuthToken();
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

