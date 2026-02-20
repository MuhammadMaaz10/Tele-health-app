import 'package:flutter/material.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/core/utils/location_utils.dart';
import 'package:telehealth_app/features/profile/model/profile_model.dart';
import '../services/users_api.dart';

class UsersProvider extends ChangeNotifier {
  final UsersApi _usersApi = UsersApi();

  // State
  bool isLoadingDoctors = false;
  bool isLoadingPatients = false;
  bool isLoadingNurses = false;
  String? error;

  List<User> _doctors = [];
  List<User> _patients = [];
  List<User> _nurses = [];

  // Getters
  List<User> get doctors => _doctors;
  List<User> get patients => _patients;
  List<User> get nurses => _nurses;

  /// Load all doctors
  Future<void> loadDoctors() async {
    if (_doctors.isNotEmpty) {
      // Already loaded, no need to reload
      return;
    }

    isLoadingDoctors = true;
    error = null;
    notifyListeners();

    try {
      final users = await _usersApi.getDoctors();
      
      // Convert locations to readable addresses
      for (var user in users) {
        if (user.location != null) {
          try {
            final address = await LocationUtils.getAddressFromCoordinates(
              latitude: user.location!.latitude,
              longitude: user.location!.longitude,
            );
            user.location!.setReadableAddress(address);
          } catch (e) {
            // If reverse geocoding fails, location will use coordinates as fallback
            debugPrint('Failed to reverse geocode location for doctor ${user.email}: $e');
          }
        }
      }
      
      _doctors = users;
      isLoadingDoctors = false;
      notifyListeners();
    } on NetworkExceptions catch (e) {
      error = e.message;
      isLoadingDoctors = false;
      notifyListeners();
    } catch (e) {
      error = 'Failed to load doctors. Please try again.';
      isLoadingDoctors = false;
      notifyListeners();
    }
  }

  /// Load all patients
  Future<void> loadPatients() async {
    if (_patients.isNotEmpty) {
      // Already loaded, no need to reload
      return;
    }

    isLoadingPatients = true;
    error = null;
    notifyListeners();

    try {
      final users = await _usersApi.getPatients();
      
      // Convert locations to readable addresses
      for (var user in users) {
        if (user.location != null) {
          try {
            final address = await LocationUtils.getAddressFromCoordinates(
              latitude: user.location!.latitude,
              longitude: user.location!.longitude,
            );
            user.location!.setReadableAddress(address);
          } catch (e) {
            // If reverse geocoding fails, location will use coordinates as fallback
            debugPrint('Failed to reverse geocode location for patient ${user.email}: $e');
          }
        }
      }
      
      _patients = users;
      isLoadingPatients = false;
      notifyListeners();
    } on NetworkExceptions catch (e) {
      error = e.message;
      isLoadingPatients = false;
      notifyListeners();
    } catch (e) {
      error = 'Failed to load patients. Please try again.';
      isLoadingPatients = false;
      notifyListeners();
    }
  }

  /// Load all nurses
  Future<void> loadNurses() async {
    if (_nurses.isNotEmpty) {
      // Already loaded, no need to reload
      return;
    }

    isLoadingNurses = true;
    error = null;
    notifyListeners();

    try {
      final users = await _usersApi.getNurses();
      
      // Convert locations to readable addresses
      for (var user in users) {
        if (user.location != null) {
          try {
            final address = await LocationUtils.getAddressFromCoordinates(
              latitude: user.location!.latitude,
              longitude: user.location!.longitude,
            );
            user.location!.setReadableAddress(address);
          } catch (e) {
            // If reverse geocoding fails, location will use coordinates as fallback
            debugPrint('Failed to reverse geocode location for nurse ${user.email}: $e');
          }
        }
      }
      
      _nurses = users;
      isLoadingNurses = false;
      notifyListeners();
    } on NetworkExceptions catch (e) {
      error = e.message;
      isLoadingNurses = false;
      notifyListeners();
    } catch (e) {
      error = 'Failed to load nurses. Please try again.';
      isLoadingNurses = false;
      notifyListeners();
    }
  }

  /// Search users by email (case-insensitive)
  List<User> searchUsersByEmail(List<User> users, String query) {
    if (query.isEmpty) return users;
    
    final lowerQuery = query.toLowerCase();
    return users.where((user) {
      return user.email.toLowerCase().contains(lowerQuery) ||
          (user.username != null && user.username!.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Find user by email
  User? findUserByEmail(List<User> users, String email) {
    try {
      return users.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Clear cached data
  void clearCache() {
    _doctors.clear();
    _patients.clear();
    _nurses.clear();
    notifyListeners();
  }
}

