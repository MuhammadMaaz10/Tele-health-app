import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/core/utils/app_endpoints.dart';
import 'package:telehealth_app/features/auth/services/auth_api.dart';
import 'package:dio/dio.dart';

class DoctorRegistrationProvider extends ChangeNotifier {
  // Controllers for text fields
  final username = TextEditingController();
  final phone = TextEditingController();
  final dob = TextEditingController();
  final gender = TextEditingController();
  final specialization = TextEditingController();
  final password = TextEditingController();

  // Step/page controller
  final PageController pageController = PageController();
  int currentStep = 0;
  String? email; // Email from signup (original case)
  String? role; // Role from signup (uppercase: DOCTOR or NURSE)
  bool isLoading = false;

  // Location coordinates (for API)
  double? latitude;
  double? longitude;

  // Specialization options - updated to match API values
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

  // File variables (replaced with new requirements)
  File? profileImage;
  PlatformFile? idDocumentFile;
  PlatformFile? practicingCertificateFile;
  PlatformFile? educationalCertificateFile;

  bool isLoadingLocation = false;
  Uint8List? profileImageBytes;

  // 📍 Location
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

      // Store coordinates for API
      latitude = position.latitude;
      longitude = position.longitude;

      // Location coordinates are stored, no need to display address
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
        profileImage = null; // Only bytes on web
      } else {
        profileImage = File(picked.path);
        profileImageBytes = null;
      }
      notifyListeners();
    }
  }


  // 📁 File Picker (works on all platforms)
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
          case "practicingCertificate":
            practicingCertificateFile = file;
            break;
          case "educationalCertificate":
            educationalCertificateFile = file;
            break;
        }
        notifyListeners();
        notifyFormChange(); // Notify to update button state
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  // 🧭 Page Navigation (3 steps now: BasicInfo, ProfessionalDetails, PendingApproval)
  void nextStep() {
    if (currentStep < 2) {
      currentStep++;
      pageController.animateToPage(
        currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      pageController.animateToPage(
        currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 2) {
      currentStep = step;
      pageController.jumpToPage(step);
      notifyListeners();
    }
  }

  final AuthApi _authApi = AuthApi();

  void setEmail(String email) {
    this.email = email;
  }

  void setRole(String role) {
    this.role = role;
  }

  // Check if form is valid
  bool get isFormValid {
    return username.text.isNotEmpty &&
        phone.text.isNotEmpty &&
        dob.text.isNotEmpty &&
        gender.text.isNotEmpty
    &&
        specialization.text.isNotEmpty &&
        // password.text.isNotEmpty &&
        idDocumentFile != null &&
        practicingCertificateFile != null &&
        educationalCertificateFile != null
    &&
        latitude != null &&
        longitude != null;
  }

  // Method to notify listeners when form fields change
  void notifyFormChange() {
    notifyListeners();
  }

  Future<void> submitRegistration(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      final formData = FormData();

      // ----------------------------------------------------
      // TEXT FIELDS
      // ----------------------------------------------------
      formData.fields.addAll([
        MapEntry('email', email ?? ''),
        MapEntry('role', role ?? ''),
        MapEntry('username', username.text.trim()),
        MapEntry('phone', phone.text.trim()),
        MapEntry('gender', gender.text.trim()),
        MapEntry('dateOfBirth', dob.text.trim()),
        MapEntry('specialization', specialization.text.trim()),
        MapEntry('password', "password.text.trim()"),
      ]);

      // ----------------------------------------------------
      // PROFILE IMAGE (WEB + MOBILE)
      // ----------------------------------------------------
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

      // ----------------------------------------------------
      // DOCUMENT HANDLER (works for WEB + MOBILE)
      // ----------------------------------------------------
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
      await addFile("medicalCertificate", practicingCertificateFile);
      await addFile("educationalCertificate", educationalCertificateFile);

      // ----------------------------------------------------
      // VALIDATION
      // ----------------------------------------------------
      if (idDocumentFile == null) throw Exception("ID Document is required");
      if (practicingCertificateFile == null) throw Exception("Medical Certificate is required");
      if (educationalCertificateFile == null) throw Exception("Educational Certificate is required");

      if (latitude == null || longitude == null) {
        throw Exception("Location is required. Please get your current location.");
      }

      // ----------------------------------------------------
      // DEBUG PRINT
      // ----------------------------------------------------
      debugPrint("===== API REQUEST BODY =====");
      debugPrint("Endpoint: ${role == 'NURSE' ? AppEndpoints.registerNurse : AppEndpoints.registerDoctor}");
      debugPrint("Location: $latitude , $longitude");
      debugPrint("Fields:");
      for (var f in formData.fields) debugPrint("  ${f.key}: ${f.value}");
      debugPrint("Files:");
      for (var f in formData.files) debugPrint("  ${f.key}: ${f.value.filename}");
      debugPrint("=============================");

      // ----------------------------------------------------
      // SEND REQUEST
      // ----------------------------------------------------
      if (role == 'NURSE') {
        await _authApi.registerNurse(
          formData: formData,
          latitude: latitude,
          longitude: longitude,
        );
      } else {
        await _authApi.registerDoctor(
          formData: formData,
          latitude: latitude,
          longitude: longitude,
        );
      }

    } on NetworkExceptions catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  @override
  void dispose() {
    pageController.dispose();
    username.dispose();
    phone.dispose();
    dob.dispose();
    gender.dispose();
    specialization.dispose();
    password.dispose();
    super.dispose();
  }
}
