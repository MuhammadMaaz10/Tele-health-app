import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/text_field.dart';

class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({Key? key}) : super(key: key);

  @override
  State<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _dobController = TextEditingController();
  final _locationController = TextEditingController();
  final _kinNameController = TextEditingController();
  final _kinSurnameController = TextEditingController();
  final _kinPhoneController = TextEditingController();

  DateTime? _selectedDate;

  // Location related
  bool _isLoadingLocation = false;
  String? _locationError;

  // Validation errors
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    _locationController.dispose();
    _kinNameController.dispose();
    _kinSurnameController.dispose();
    _kinPhoneController.dispose();
    super.dispose();
  }

  // MARK: - Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back Arrow
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(Icons.arrow_back_outlined,
                              color: AppColors.textColor, size: 24),
                        ),
                        kGap16,

                        CustomText(
                          text: "Complete your profile",
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textColor,
                        ),
                        kGap8,
                        CustomText(
                          text: "Fill in the details to continue",
                          color: AppColors.hintColor,
                        ),
                        kGap30,

                        _buildValidatedField(
                          controller: _firstNameController,
                          label: "First Name",
                          fieldKey: "firstName",
                        ),
                        _buildValidatedField(
                          controller: _lastNameController,
                          label: "Last Name",
                          fieldKey: "lastName",
                        ),
                        _buildValidatedField(
                          controller: _phoneController,
                          label: "Phone Number",
                          fieldKey: "phone",
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icon(Icons.phone_outlined,
                              color: AppColors.hintColor, size: 20),
                        ),
                        _buildValidatedField(
                          controller: _ageController,
                          label: "Age",
                          fieldKey: "age",
                          keyboardType: TextInputType.number,
                        ),
                        _buildValidatedField(
                          controller: _genderController,
                          label: "Gender",
                          fieldKey: "gender",
                          readOnly: true,
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                          onTap: () async {
                            final gender = await showModalBottomSheet<String>(
                              context: context,
                              builder: (_) => const GenderPickerSheet(),
                            );
                            if (gender != null) {
                              setState(() {
                                _genderController.text = gender;
                                _errors["gender"] = null;
                              });
                            }
                          },
                        ),
                        _buildValidatedField(
                          controller: _dobController,
                          label: "Date of Birth",
                          fieldKey: "dob",
                          readOnly: true,
                          suffixIcon: Icon(Icons.calendar_today_outlined,
                              color: AppColors.hintColor, size: 20),
                          onTap: _pickDate,
                        ),
                        _buildLocationField(),

                        kGap30,
                        CustomText(
                          text: "Next of Kin",
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColor,
                        ),
                        kGap16,
                        _buildValidatedField(
                          controller: _kinNameController,
                          label: "Name",
                          fieldKey: "kinName",
                        ),
                        _buildValidatedField(
                          controller: _kinSurnameController,
                          label: "Surname",
                          fieldKey: "kinSurname",
                        ),
                        _buildValidatedField(
                          controller: _kinPhoneController,
                          label: "Phone Number",
                          fieldKey: "kinPhone",
                          keyboardType: TextInputType.phone,
                        ),

                        const Spacer(),

                        CustomButton(
                          text: "Complete Profile",
                          onPressed: _isFormValid ? _handleSubmit : null,
                          backgroundColor: _isFormValid
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // MARK: - Validation and UI Builders
  Widget _buildValidatedField({
    required TextEditingController controller,
    required String label,
    required String fieldKey,
    TextInputType? keyboardType,
    bool readOnly = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            hintText: label,
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            onTap: onTap,
            onChanged: (_) {
              setState(() {
                _validateField(fieldKey, controller.text);
              });
            },
          ),
          if (_errors[fieldKey] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: CustomText(
                text: _errors[fieldKey]!,
                color: Colors.red,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            hintText: "Your Location",
            controller: _locationController,
            prefixIcon: Icon(Icons.location_on_outlined,
                color: AppColors.hintColor, size: 20),
            suffixIcon: _isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.my_location_outlined,
                        color: AppColors.primary, size: 20),
                    onPressed: _getCurrentLocation,
                  ),
            onChanged: (_) {
              setState(() {
                _validateField("location", _locationController.text);
              });
            },
          ),
          if (_errors["location"] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: CustomText(
                text: _errors["location"]!,
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          if (_locationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: CustomText(
                text: _locationError!,
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  void _validateField(String key, String value) {
    switch (key) {
      case "firstName":
      case "lastName":
      case "gender":
      case "dob":
      case "location":
      case "kinName":
      case "kinSurname":
        _errors[key] = value.isEmpty ? "This field is required" : null;
        break;
      case "phone":
      case "kinPhone":
        _errors[key] = value.isEmpty
            ? "This field is required"
            : value.length < 10
            ? "Enter valid phone number"
            : null;
        break;
      case "age":
        _errors[key] = value.isEmpty
            ? "Required"
            : int.tryParse(value) == null
            ? "Enter valid number"
            : null;
        break;
    }
  }

  bool get _isFormValid {
    // Clear previous errors
    _errors.clear();
    
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
      _validateField(key, _getControllerValue(key));
    }
    return !_errors.values.any((e) => e != null);
  }

  String _getControllerValue(String key) {
    switch (key) {
      case "firstName":
        return _firstNameController.text;
      case "lastName":
        return _lastNameController.text;
      case "phone":
        return _phoneController.text;
      case "age":
        return _ageController.text;
      case "gender":
        return _genderController.text;
      case "dob":
        return _dobController.text;
      case "location":
        return _locationController.text;
      case "kinName":
        return _kinNameController.text;
      case "kinSurname":
        return _kinSurnameController.text;
      case "kinPhone":
        return _kinPhoneController.text;
      default:
        return '';
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
        "${picked.day}/${picked.month}/${picked.year}";
        _errors["dob"] = null;
      });
    }
  }

  // Future<void> _getCurrentLocation() async {
  // MARK: - Location Methods
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = "Location services are disabled. Please enable them in settings.";
        });
        return;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
            _locationError = "Location permission denied. Please enable location access.";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = "Location permissions are permanently denied. Please enable them in app settings.";
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Convert coordinates to address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = _formatAddress(place);
        
        setState(() {
          _locationController.text = address;
          _isLoadingLocation = false;
          _locationError = null;
          _errors["location"] = null;
        });
      } else {
        setState(() {
          _isLoadingLocation = false;
          _locationError = "Could not determine address from coordinates.";
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = "Failed to get location: ${e.toString()}";
      });
      debugPrint("Error fetching location: $e");
    }
  }

  String _formatAddress(Placemark place) {
    List<String> addressParts = [];
    
    if (place.street?.isNotEmpty == true) addressParts.add(place.street!);
    if (place.locality?.isNotEmpty == true) addressParts.add(place.locality!);
    if (place.administrativeArea?.isNotEmpty == true) addressParts.add(place.administrativeArea!);
    if (place.country?.isNotEmpty == true) addressParts.add(place.country!);
    
    return addressParts.join(", ");
  }

  void _handleSubmit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile Completed Successfully!")),
    );
  }
}

class GenderPickerSheet extends StatelessWidget {
  const GenderPickerSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final genders = ["Male", "Female", "Other"];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: genders
            .map(
              (g) => ListTile(
            title: Text(g),
            onTap: () => Navigator.pop(context, g),
          ),
        )
            .toList(),
      ),
    );
  }
}
