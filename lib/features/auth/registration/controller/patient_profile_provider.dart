import 'dart:io';
import 'package:flutter/material.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/features/auth/services/auth_api.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class PatientProfileProvider extends ChangeNotifier {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final genderController = TextEditingController();
  final dobController = TextEditingController();
  final locationController = TextEditingController();
  //
  final Map<String, String?> errors = {};

  bool isLoadingLocation = false;
  String? locationError;
  DateTime? selectedDate;

  bool isLoading = false;

  File? profileImage;
  File? idDocument;

  Uint8List? profileImageBytes;   // for WEB
  Uint8List? idDocumentBytes;

  // Location coordinates (for API)
  double? latitude;
  double? longitude;

  // ---------------------------------------------------------
  // VALIDATION
  // ---------------------------------------------------------
  void validateField(String key, String value) {
    switch (key) {
      case "firstName":
      case "lastName":
      case "gender":
      case "dob":
      case "location":
      case "kinName":
      case "kinSurname":
        errors[key] = value.isEmpty ? "This field is required" : null;
        break;
      case "phone":
      case "kinPhone":
        errors[key] = value.isEmpty
            ? "This field is required"
            : value.length < 10
            ? "Enter valid phone number"
            : null;
        break;
    }
    notifyListeners();
  }

  bool get isFormValid {
    return [
      firstNameController.text,
      lastNameController.text,
      phoneController.text,
      genderController.text,
      dobController.text,
      locationController.text,
    ].every((v) => v.trim().isNotEmpty);
  }

  void validateAllFields() {
    for (var key in [
      "firstName",
      "lastName",
      "phone",
      "gender",
      "dob",
      "location",
    ]) {
      validateField(key, getControllerValue(key));
    }
  }

  String getControllerValue(String key) {
    switch (key) {
      case "firstName":
        return firstNameController.text;
      case "lastName":
        return lastNameController.text;
      case "phone":
        return phoneController.text;
      case "gender":
        return genderController.text;
      case "dob":
        return dobController.text;
      case "location":
        return locationController.text;
      default:
        return '';
    }
  }

  // ---------------------------------------------------------
  // IMAGE PICKERS
  // ---------------------------------------------------------
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

  Future<void> pickIdDocument(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      final file = result.files.single;

      if (kIsWeb) {
        idDocumentBytes = file.bytes;
        idDocument = null;
      } else {
        if (file.path != null) {
          idDocument = File(file.path!);
          idDocumentBytes = null;
        }
      }
      notifyListeners();
    }
  }


  // ---------------------------------------------------------
  // LOCATION LOGIC
  // ---------------------------------------------------------
  Future<void> getCurrentLocation() async {
    isLoadingLocation = true;
    locationError = null;
    notifyListeners();

    try {
      // --------- WEB-SPECIFIC CHECKS ----------
      if (kIsWeb) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          locationError = "Location services are disabled on your browser.";
          isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      // --------- PERMISSIONS ----------
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationError = "Location permission denied.";
          isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        locationError =
        "Location permission permanently denied. Enable it in browser/app settings.";
        isLoadingLocation = false;
        notifyListeners();
        return;
      }

      // --------- GET COORDINATES ----------
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        forceAndroidLocationManager: false,
      );

      latitude = position.latitude;
      longitude = position.longitude;

      // --------- TRY REVERSE GEOCODING (MAY FAIL ON WEB) ----------
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          locationController.text = _formatAddress(p);
        } else {
          locationController.text =
          "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        }

        errors["location"] = null;
      } catch (geoError) {
        // If reverse geocoding fails (COMMON ON WEB)
        locationController.text =
        "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        errors["location"] = null;
      }
    } catch (e) {
      // --------- ANY ERROR HERE IS WEB MOSTLY ----------
      print("GEO ERROR: $e");

      if (kIsWeb) {
        locationError =
        "Browser blocked location or running without HTTPS.\nError: ${e.toString()}";
      } else {
        locationError = "Failed to get location: ${e.toString()}";
      }
    }

    isLoadingLocation = false;
    notifyListeners();
  }


  String _formatAddress(Placemark place) {
    List<String> addressParts = [];
    if (place.street?.isNotEmpty == true) addressParts.add(place.street!);
    if (place.locality?.isNotEmpty == true) addressParts.add(place.locality!);
    if (place.administrativeArea?.isNotEmpty == true)
      addressParts.add(place.administrativeArea!);
    if (place.country?.isNotEmpty == true) addressParts.add(place.country!);
    return addressParts.join(", ");
  }

  // ---------------------------------------------------------
  // DOB PICKER
  // ---------------------------------------------------------
  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      selectedDate = picked;
      // Format: dd-MM-yyyy (e.g., 22-01-1999)
      dobController.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      errors["dob"] = null;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------
  // SUBMIT
  // ---------------------------------------------------------
  bool handleSubmit(BuildContext context) {
    validateAllFields();
    if (errors.values.any((e) => e != null)) {
      notifyListeners();
      return false;
    }
    submitToApi(context);
    return true;
  }

  final AuthApi _authApi = AuthApi();

  String? email; // Email from signup (original case)
  String? role; // Role from signup (uppercase: PATIENT)

  void setEmail(String email) {
    this.email = email;
  }
  
  void setRole(String role) {
    this.role = role;
  }

  Future<void> submitToApi(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      final formData = FormData();

      // -----------------------------
      // TEXT FIELDS
      // -----------------------------
      formData.fields.addAll([
        MapEntry('email', email ?? ''),
        MapEntry('role', role ?? ''),
        MapEntry('username', firstNameController.text.trim()),
        MapEntry('phone', phoneController.text.trim()),
        MapEntry('gender', genderController.text.trim().toLowerCase()),
        MapEntry('dateOfBirth', dobController.text.trim()),
        MapEntry('password', 'empty'),
      ]);

      // -----------------------------
      // PROFILE IMAGE (WEB + MOBILE)
      // -----------------------------
      if (kIsWeb && profileImageBytes != null) {
        formData.files.add(
          MapEntry(
            'profilePicture',
            MultipartFile.fromBytes(
              profileImageBytes!,
              filename: "profile.png",
            ),
          ),
        );
      } else if (!kIsWeb && profileImage != null) {
        formData.files.add(
          MapEntry(
            'profilePicture',
            await MultipartFile.fromFile(
              profileImage!.path,
              filename: profileImage!.path.split('/').last,
            ),
          ),
        );
      }

      // -----------------------------
      // ID DOCUMENT (WEB + MOBILE)
      // -----------------------------
      if (kIsWeb && idDocumentBytes != null) {
        formData.files.add(
          MapEntry(
            'idDocument',
            MultipartFile.fromBytes(
              idDocumentBytes!,
              filename: "id_document",
            ),
          ),
        );
      } else if (!kIsWeb && idDocument != null) {
        formData.files.add(
          MapEntry(
            'idDocument',
            await MultipartFile.fromFile(
              idDocument!.path,
              filename: idDocument!.path.split('/').last,
            ),
          ),
        );
      }

      // -----------------------------
      // SEND API
      // -----------------------------
      await _authApi.registerPatient(
        formData: formData,
        latitude: latitude,
        longitude: longitude,
      );

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


  // ---------------------------------------------------------
  // CLEANUP
  // ---------------------------------------------------------
  void disposeControllers() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    genderController.dispose();
    dobController.dispose();
    locationController.dispose();
  }
}
