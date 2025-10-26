import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class PatientProfileProvider extends ChangeNotifier {
  // Controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();
  final genderController = TextEditingController();
  final dobController = TextEditingController();
  final locationController = TextEditingController();
  final kinNameController = TextEditingController();
  final kinSurnameController = TextEditingController();
  final kinPhoneController = TextEditingController();

  // Validation
  final Map<String, String?> errors = {};

  // Location
  bool isLoadingLocation = false;
  String? locationError;

  DateTime? selectedDate;

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
      case "age":
        errors[key] = value.isEmpty
            ? "Required"
            : int.tryParse(value) == null
            ? "Enter valid number"
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
      ageController.text,
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
      "age",
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
      case "age":
        return ageController.text;
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

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile Completed Successfully!")),
    );
    return true;
  }

  // ---------------------------------------------------------
  // CLEANUP
  // ---------------------------------------------------------
  void disposeControllers() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    ageController.dispose();
    genderController.dispose();
    dobController.dispose();
    locationController.dispose();
    kinNameController.dispose();
    kinSurnameController.dispose();
    kinPhoneController.dispose();
  }
}
