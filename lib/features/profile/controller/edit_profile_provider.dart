import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/features/auth/services/auth_api.dart';
import 'package:dio/dio.dart';
import '../model/profile_model.dart';

class EditProfileProvider extends ChangeNotifier {
  final AuthApi _authApi = AuthApi();

  // Controllers
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final genderController = TextEditingController();
  final dobController = TextEditingController();
  final locationController = TextEditingController();
  final specializationController = TextEditingController();

  // State
  bool isLoading = false;
  bool isLoadingLocation = false;
  String? error;
  String? userRole;
  String? userEmail;

  // Location
  double? latitude;
  double? longitude;

  // Files
  File? profileImage;
  PlatformFile? idDocumentFile;
  PlatformFile? medicalCertificateFile;
  PlatformFile? educationalCertificateFile;
  Uint8List? profileImageBytes;

  // Specialization options (for Doctor/Nurse)
  final List<String> specializationOptions = [
    "PSYCHOLOGY",
    "CARDIOLOGY",
    "DERMATOLOGY",
    "NEUROLOGY",
    "ORTHOPEDICS",
    "PSYCHIATRY",
    "GENERAL",
    "OTHER",
  ];

  void initializeFromUser(User user, String role, String email) {
    userRole = role;
    userEmail = email;
    
    usernameController.text = user.username ?? '';
    phoneController.text = user.phone ?? '';
    genderController.text = user.gender?.toUpperCase() ?? '';
    dobController.text = _formatDateForInput(user.dob) ?? '';
    specializationController.text = user.specialization ?? '';
    
    if (user.location != null) {
      latitude = user.location!.latitude;
      longitude = user.location!.longitude;
      locationController.text = user.location!.formatted;
    }
    
    notifyListeners();
  }

  String? _formatDateForInput(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      final dateStr = dateString.split('T').first;
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1]}-${parts[0]}'; // DD-MM-YYYY
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  Future<void> getCurrentLocation() async {
    isLoadingLocation = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        isLoadingLocation = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        isLoadingLocation = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude = position.latitude;
      longitude = position.longitude;
      locationController.text =
          "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
    } catch (e) {
      debugPrint("Error getting location: $e");
    }

    isLoadingLocation = false;
    notifyListeners();
  }

  Future<void> pickProfileImage(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        profileImageBytes = await picked.readAsBytes();
        profileImage = null;
      } else {
        profileImage = File(picked.path);
        profileImageBytes = null;
      }
      notifyListeners();
    }
  }

  Future<void> pickFile(String type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["pdf", "jpg", "jpeg", "png"],
      );

      if (result != null) {
        final file = result.files.single;
        switch (type) {
          case "idDocument":
            idDocumentFile = file;
            break;
          case "medicalCertificate":
            medicalCertificateFile = file;
            break;
          case "educationalCertificate":
            educationalCertificateFile = file;
            break;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  Future<void> updateProfile(BuildContext context) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final formData = FormData();

      // Text fields (all optional)
      if (usernameController.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('username', usernameController.text.trim()));
      }
      if (phoneController.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('phone', phoneController.text.trim()));
      }
      if (genderController.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('gender', genderController.text.trim().toLowerCase()));
      }
      if (dobController.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('dateOfBirth', _convertToApiDateFormat(dobController.text.trim())));
      }
      if (userRole == 'DOCTOR' || userRole == 'NURSE') {
        if (specializationController.text.trim().isNotEmpty) {
          formData.fields.add(MapEntry('specialization', specializationController.text.trim()));
        }
      }

      // Profile picture
      if (kIsWeb) {
        if (profileImageBytes != null) {
          formData.files.add(
            MapEntry(
              'profilePicture',
              MultipartFile.fromBytes(
                profileImageBytes!,
                filename: "profile.png",
              ),
            ),
          );
        }
      } else {
        if (profileImage != null) {
          formData.files.add(
            MapEntry(
              'profilePicture',
              await MultipartFile.fromFile(
                profileImage!.path,
                filename: profileImage!.path.split(Platform.pathSeparator).last,
              ),
            ),
          );
        }
      }

      // Documents (optional)
      Future<void> addFile(String key, PlatformFile? file) async {
        if (file == null) return;

        if (kIsWeb) {
          formData.files.add(
            MapEntry(
              key,
              MultipartFile.fromBytes(
                file.bytes!,
                filename: file.name,
              ),
            ),
          );
        } else {
          formData.files.add(
            MapEntry(
              key,
              await MultipartFile.fromFile(
                file.path!,
                filename: file.name,
              ),
            ),
          );
        }
      }

      await addFile("idDocument", idDocumentFile);
      if (userRole == 'DOCTOR' || userRole == 'NURSE') {
        await addFile("medicalCertificate", medicalCertificateFile);
        await addFile("educationalCertificate", educationalCertificateFile);
      }

      // Update API call
      await _authApi.updateUser(
        formData: formData,
        latitude: latitude,
        longitude: longitude,
      );

      // Success
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully ✅")),
        );
      }
    } on NetworkExceptions catch (e) {
      error = e.message;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      error = 'Failed to update profile. Please try again.';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error!)),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _convertToApiDateFormat(String dateStr) {
    // Convert DD-MM-YYYY to YYYY-MM-DD
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    phoneController.dispose();
    genderController.dispose();
    dobController.dispose();
    locationController.dispose();
    specializationController.dispose();
    super.dispose();
  }
}

