import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class DoctorRegistrationProvider extends ChangeNotifier {
  // Controllers for text fields
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final practiceNumber = TextEditingController();
  final age = TextEditingController();
  final gender = TextEditingController();
  final location = TextEditingController();
  final specialization = TextEditingController();
  final experience = TextEditingController();

  // Step/page controller
  final PageController pageController = PageController();
  int currentStep = 0;

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

  // File variables
  PlatformFile? certificateFile;
  PlatformFile? idFrontFile;
  PlatformFile? idBackFile;

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
        type: type == "certificate" ? FileType.custom : FileType.image,
        allowedExtensions:
        type == "certificate" ? ["pdf", "jpg", "jpeg", "png"] : null,
      );

      if (result != null) {
        final file = result.files.single;
        switch (type) {
          case "certificate":
            certificateFile = file;
            break;
          case "idFront":
            idFrontFile = file;
            break;
          case "idBack":
            idBackFile = file;
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

  @override
  void dispose() {
    pageController.dispose();
    firstName.dispose();
    lastName.dispose();
    phone.dispose();
    practiceNumber.dispose();
    age.dispose();
    gender.dispose();
    location.dispose();
    specialization.dispose();
    experience.dispose();
    super.dispose();
  }
}
