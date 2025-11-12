import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/features/auth/services/auth_api.dart';

class DoctorRegistrationProvider extends ChangeNotifier {
  // Controllers for text fields
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final practiceNumber = TextEditingController();
  final role = TextEditingController();
  final dob = TextEditingController();
  final gender = TextEditingController();
  final location = TextEditingController();
  final specialization = TextEditingController();
  final experience = TextEditingController();

  // Step/page controller
  final PageController pageController = PageController();
  int currentStep = 0;
  String? email; // Email from signup
  bool isLoading = false;

  // Specialization options
  final List<String> specializationOptions = [
    "General Physician",
    "Cardiologist",
    "Dentist",
    "Dermatologist",
    "Neurologist",
    "Orthopedic",
    "Psychiatrist",
    "Other",
  ];

  // File variables (replaced with new requirements)
  PlatformFile? idDocumentFile;
  PlatformFile? practicingCertificateFile;
  PlatformFile? educationalCertificateFile;

  bool isLoadingLocation = false;

  // Availability
  Map<String, Map<String, TimeOfDay?>> availability = {
    "Monday": {"start": null, "end": null},
    "Tuesday": {"start": null, "end": null},
    "Wednesday": {"start": null, "end": null},
    "Thursday": {"start": null, "end": null},
    "Friday": {"start": null, "end": null},
    "Saturday": {"start": null, "end": null},
    "Sunday": {"start": null, "end": null},
  };

  List<String> selectedDays = [];

  // 📍 Location
  Future<void> getCurrentLocation() async {
    isLoadingLocation = true;
    notifyListeners();

    try {
      final position = await Geolocator.getCurrentPosition();
      location.text =
      "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
    } catch (e) {
      debugPrint("Error getting location: $e");
    }

    isLoadingLocation = false;
    notifyListeners();
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
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  // 🧭 Page Navigation
  void nextStep() {
    if (currentStep < 3) {
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
    if (step >= 0 && step <= 3) {
      currentStep = step;
      pageController.jumpToPage(step);
      notifyListeners();
    }
  }

  final AuthApi _authApi = AuthApi();

  void setEmail(String email) {
    this.email = email;
  }

  Future<void> submitRegistration(BuildContext context) async {
    isLoading = true;
    notifyListeners();
    try {
      final payload = <String, dynamic>{
        'email': email ?? '',
        'firstName': firstName.text.trim(),
        'lastName': lastName.text.trim(),
        'phone': phone.text.trim(),
        'practiceNumber': practiceNumber.text.trim(),
        'role': role.text.trim().isEmpty ? 'doctor' : role.text.trim(),
        'dob': dob.text.trim(),
        'gender': gender.text.trim(),
        'location': location.text.trim(),
        'specialization': specialization.text.trim(),
        'experience': experience.text.trim(),
        'availability': availability,
        // Files can be sent as multipart later; placeholder fields
      };
      await _authApi.registerDoctor(payload: payload);
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
    firstName.dispose();
    lastName.dispose();
    phone.dispose();
    practiceNumber.dispose();
    dob.dispose();
    role.dispose();
    gender.dispose();
    location.dispose();
    specialization.dispose();
    experience.dispose();
    super.dispose();
  }
}
