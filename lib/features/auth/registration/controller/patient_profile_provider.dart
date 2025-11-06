import 'dart:io';
import 'package:flutter/material.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/features/auth/services/auth_api.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class PatientProfileProvider extends ChangeNotifier {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final genderController = TextEditingController();
  final dobController = TextEditingController();
  final locationController = TextEditingController();
  final kinNameController = TextEditingController();
  final kinSurnameController = TextEditingController();
  final kinPhoneController = TextEditingController();

  final Map<String, String?> errors = {};

  bool isLoadingLocation = false;
  String? locationError;
  DateTime? selectedDate;

  File? profileImage;
  File? idDocument;

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
      kinNameController.text,
      kinSurnameController.text,
      kinPhoneController.text,
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
      "kinName",
      "kinSurname",
      "kinPhone"
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
      case "kinName":
        return kinNameController.text;
      case "kinSurname":
        return kinSurnameController.text;
      case "kinPhone":
        return kinPhoneController.text;
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
      profileImage = File(picked.path);
      notifyListeners();
    }
  }

  Future<void> pickIdDocument(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      idDocument = File(result.files.single.path!);
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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        isLoadingLocation = false;
        locationError = "Location services are disabled.";
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          isLoadingLocation = false;
          locationError = "Location permission denied.";
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        isLoadingLocation = false;
        locationError =
        "Location permissions are permanently denied. Please enable them in app settings.";
        notifyListeners();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = _formatAddress(place);
        locationController.text = address;
        errors["location"] = null;
      } else {
        locationError = "Could not determine address.";
      }
    } catch (e) {
      locationError = "Failed to get location: ${e.toString()}";
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
      dobController.text = "${picked.day}/${picked.month}/${picked.year}";
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

  Future<void> submitToApi(BuildContext context) async {
    try {
      final payload = <String, dynamic>{
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'gender': genderController.text.trim(),
        'dob': dobController.text.trim(),
        'location': locationController.text.trim(),
        'kin': {
          'name': kinNameController.text.trim(),
          'surname': kinSurnameController.text.trim(),
          'phone': kinPhoneController.text.trim(),
        },
      };

      await _authApi.registerPatient(payload: payload);
      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient registered successfully.')),
      );
    } on NetworkExceptions catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
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
    kinNameController.dispose();
    kinSurnameController.dispose();
    kinPhoneController.dispose();
  }
}
