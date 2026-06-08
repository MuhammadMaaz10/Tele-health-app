import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:telehealth_app/core/auth/auth_error_mapper.dart';
import 'package:telehealth_app/core/supabase/auth_email_check.dart';
import 'package:telehealth_app/core/navigation/main_navigation.dart';
import 'package:telehealth_app/core/supabase/pending_registration.dart';
import 'package:telehealth_app/core/supabase/supabase_profile_service.dart';
import 'package:telehealth_app/features/auth/otp_verification/views/otp_view.dart';

class DoctorRegistrationProvider extends ChangeNotifier {
  // Controllers for text fields
  final username = TextEditingController();
  final phone = TextEditingController();
  final dob = TextEditingController();
  final gender = TextEditingController();
  final specialization = TextEditingController();
  final password = TextEditingController();
  final locationController = TextEditingController();

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

      locationController.text =
      "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";


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

  String? _otpAlreadySentForEmail;

  void setEmail(String email) {
    final e = email.trim();
    if (this.email != null &&
        this.email!.isNotEmpty &&
        this.email!.toLowerCase() != e.toLowerCase()) {
      _clearFormForNewEmail();
    }
    if (this.email != e) {
      _otpAlreadySentForEmail = null;
    }
    this.email = e;
  }

  void _clearFormForNewEmail() {
    username.clear();
    phone.clear();
    dob.clear();
    gender.clear();
    specialization.clear();
    password.clear();
    locationController.clear();
    profileImage = null;
    profileImageBytes = null;
    idDocumentFile = null;
    practicingCertificateFile = null;
    educationalCertificateFile = null;
    latitude = null;
    longitude = null;
    currentStep = 0;
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }
    notifyListeners();
  }

  void setRole(String role) {
    this.role = role;
  }

  // Check if form is valid
  bool get isFormValid {
    return username.text.isNotEmpty &&
        phone.text.isNotEmpty &&
        dob.text.isNotEmpty &&
        gender.text.isNotEmpty &&
        specialization.text.isNotEmpty &&
        // password.text.isNotEmpty &&
        idDocumentFile != null &&
        practicingCertificateFile != null &&
        educationalCertificateFile != null &&
        locationController.text.trim().isNotEmpty &&
        latitude != null &&
        longitude != null;
  }

  // Method to notify listeners when form fields change
  void notifyFormChange() {
    notifyListeners();
  }

  Future<List<int>> _bytesFromPlatformFile(PlatformFile f) async {
    if (f.bytes != null) return f.bytes!;
    if (f.path != null) return File(f.path!).readAsBytes();
    throw Exception('Missing file data');
  }

  /// Saves doctor/nurse profile to Supabase (requires active session).
  Future<void> saveDoctorProfileToSupabase(BuildContext context) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not signed in. Verify your email code first.')),
        );
      }
      return;
    }

    if (idDocumentFile == null ||
        practicingCertificateFile == null ||
        educationalCertificateFile == null) {
      throw Exception('All documents are required.');
    }
    if (latitude == null || longitude == null) {
      throw Exception('Location is required.');
    }

    final uid = user.id;
    final em = user.email ?? email ?? '';
    final roleName = (role ?? 'DOCTOR').toUpperCase() == 'NURSE' ? 'NURSE' : 'DOCTOR';

    isLoading = true;
    notifyListeners();

    try {
      String? profileUrl;
      if (kIsWeb && profileImageBytes != null) {
        profileUrl = await SupabaseProfileService.uploadBytesForUser(
          uid: uid,
          bucket: 'avatars',
          bytes: profileImageBytes!,
          filename: 'profile.png',
        );
      } else if (!kIsWeb && profileImage != null) {
        final bytes = await profileImage!.readAsBytes();
        profileUrl = await SupabaseProfileService.uploadBytesForUser(
          uid: uid,
          bucket: 'avatars',
          bytes: bytes,
          filename: profileImage!.path,
        );
      }

      final idBytes = await _bytesFromPlatformFile(idDocumentFile!);
      final medBytes = await _bytesFromPlatformFile(practicingCertificateFile!);
      final eduBytes = await _bytesFromPlatformFile(educationalCertificateFile!);

      final idPath = await SupabaseProfileService.uploadBytesForUser(
        uid: uid,
        bucket: 'documents',
        bytes: idBytes,
        filename: idDocumentFile!.name,
      );
      final medPath = await SupabaseProfileService.uploadBytesForUser(
        uid: uid,
        bucket: 'documents',
        bytes: medBytes,
        filename: practicingCertificateFile!.name,
      );
      final eduPath = await SupabaseProfileService.uploadBytesForUser(
        uid: uid,
        bucket: 'documents',
        bytes: eduBytes,
        filename: educationalCertificateFile!.name,
      );

      final parsedDob = SupabaseProfileService.parseDobDayFirst(dob.text.trim());
      final dobStr = parsedDob != null
          ? '${parsedDob.year}-${parsedDob.month.toString().padLeft(2, '0')}-${parsedDob.day.toString().padLeft(2, '0')}'
          : null;

      await SupabaseProfileService.upsertProfileRow(
        userId: uid,
        fields: {
          'email': em,
          'username': username.text.trim(),
          'phone': phone.text.trim(),
          'gender': gender.text.trim(),
          if (dobStr != null) 'dob': dobStr,
          'specialization': specialization.text.trim(),
          'latitude': latitude,
          'longitude': longitude,
          if (profileUrl != null) 'profile_pic_url': profileUrl,
          if (idPath != null) 'id_document_url': idPath,
          if (medPath != null) 'medical_certificate_url': medPath,
          if (eduPath != null) 'educational_certificate_url': eduPath,
          'enabled': true,
          'approval_status': 'pending',
        },
      );

      await SupabaseProfileService.upsertUserRole(userId: uid, roleName: roleName);

      _otpAlreadySentForEmail = null;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration saved. Awaiting approval.')),
        );
      }
    } catch (e, st) {
      debugPrint('saveDoctorProfileToSupabase: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitRegistration(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      if (idDocumentFile == null ||
          practicingCertificateFile == null ||
          educationalCertificateFile == null) {
        throw Exception('All documents are required.');
      }
      if (latitude == null || longitude == null) {
        throw Exception('Location is required. Please get your current location.');
      }

      final targetEmail = email?.trim() ?? '';
      if (targetEmail.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email is missing. Go back and try again.')),
          );
        }
        return;
      }

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null &&
          session.user.email?.toLowerCase() == targetEmail.toLowerCase()) {
        await saveDoctorProfileToSupabase(context);
        if (context.mounted) {
          Get.offAll(() => const MainNavigation());
        }
        return;
      }

      final check = await fetchSignupEmailStatus(targetEmail);
      if (check.status == SignupEmailStatus.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email already registered, please login.'),
            ),
          );
        }
        return;
      }
      final shouldCreate = check.shouldCreateAuthUser;

      PendingRegistration.completeDoctorProfileAfterOtp = true;

      final alreadySent = _otpAlreadySentForEmail != null &&
          _otpAlreadySentForEmail!.toLowerCase() == targetEmail.toLowerCase();

      if (!alreadySent) {
        await Supabase.instance.client.auth.signInWithOtp(
          email: targetEmail,
          shouldCreateUser: shouldCreate,
        );
        _otpAlreadySentForEmail = targetEmail;
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Use the code already emailed to you. If it expired, wait a few minutes before trying again.',
            ),
          ),
        );
      }

      if (context.mounted) {
        Get.to(
          () => VerifyEmailView(
            email: targetEmail,
            isRegistration: true,
            shouldCreateAuthUser: shouldCreate,
          ),
        );
      }
    } on AuthException catch (e) {
      PendingRegistration.completeDoctorProfileAfterOtp = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessageForAuthException(e, flow: AuthFlow.signup)),
          ),
        );
      }
    } catch (e) {
      PendingRegistration.completeDoctorProfileAfterOtp = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
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
    locationController.dispose();
    super.dispose();
  }
}
