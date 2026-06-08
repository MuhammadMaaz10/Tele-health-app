import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:telehealth_app/core/auth/auth_error_mapper.dart';
import 'package:telehealth_app/core/supabase/auth_email_check.dart';
import 'package:telehealth_app/core/supabase/pending_registration.dart';
import 'package:telehealth_app/core/supabase/supabase_profile_service.dart';
import 'package:telehealth_app/core/navigation/main_navigation.dart';
import 'package:telehealth_app/features/auth/otp_verification/views/otp_view.dart';

class PatientProfileProvider extends ChangeNotifier {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final genderController = TextEditingController();
  final dobController = TextEditingController();
  final locationController = TextEditingController();

  bool isLoading = false;
  bool isLoadingLocation = false;

  File? profileImage;
  File? idDocument;

  Uint8List? profileImageBytes;
  Uint8List? idDocumentBytes;

  double? latitude;
  double? longitude;

  String? email;
  String? role;

  /// Avoids calling [signInWithOtp] again for the same email (each call counts toward Supabase email rate limits).
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
    firstNameController.clear();
    lastNameController.clear();
    phoneController.clear();
    genderController.clear();
    dobController.clear();
    locationController.clear();
    profileImage = null;
    idDocument = null;
    profileImageBytes = null;
    idDocumentBytes = null;
    latitude = null;
    longitude = null;
    notifyListeners();
  }

  void setRole(String role) {
    this.role = role;
  }

  bool get isFormValid {
    return firstNameController.text.trim().isNotEmpty &&
        lastNameController.text.trim().isNotEmpty &&
        phoneController.text.trim().length >= 10 &&
        genderController.text.trim().isNotEmpty &&
        dobController.text.trim().isNotEmpty &&
        locationController.text.trim().isNotEmpty &&
        latitude != null &&
        longitude != null;
  }

  void notifyFormChange() {
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
      notifyFormChange();
    }
  }

  Future<void> pickIdDocument(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      if (kIsWeb) {
        idDocumentBytes = result.files.single.bytes;
        idDocument = null;
      } else {
        idDocument = File(result.files.single.path!);
        idDocumentBytes = null;
      }
      notifyFormChange();
    }
  }

  Future<void> getCurrentLocation() async {
    isLoadingLocation = true;
    notifyListeners();

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      latitude = position.latitude;
      longitude = position.longitude;

      locationController.text =
          "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
    } catch (e) {
      debugPrint("Location error: $e");
    }

    isLoadingLocation = false;
    notifyFormChange();
  }

  /// Saves patient profile to Supabase Storage + Postgres (requires an active session).
  Future<void> savePatientProfileToSupabase(BuildContext context) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not signed in. Please verify your email code first.')),
        );
      }
      return;
    }

    final uid = user.id;
    final em = user.email ?? email ?? '';

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

      String? idPath;
      if (kIsWeb && idDocumentBytes != null) {
        idPath = await SupabaseProfileService.uploadBytesForUser(
          uid: uid,
          bucket: 'documents',
          bytes: idDocumentBytes!,
          filename: 'id_doc.png',
        );
      } else if (!kIsWeb && idDocument != null) {
        final bytes = await idDocument!.readAsBytes();
        idPath = await SupabaseProfileService.uploadBytesForUser(
          uid: uid,
          bucket: 'documents',
          bytes: bytes,
          filename: idDocument!.path,
        );
      }

      final dob = SupabaseProfileService.parseDobDayFirst(dobController.text.trim());
      final dobStr = dob != null
          ? '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}'
          : null;

      await SupabaseProfileService.upsertProfileRow(
        userId: uid,
        fields: {
          'email': em,
          'username': firstNameController.text.trim(),
          'phone': phoneController.text.trim(),
          'gender': genderController.text.trim().toLowerCase(),
          if (dobStr != null) 'dob': dobStr,
          'latitude': latitude,
          'longitude': longitude,
          if (profileUrl != null) 'profile_pic_url': profileUrl,
          if (idPath != null) 'id_document_url': idPath,
          'enabled': true,
          'approval_status': 'approved',
        },
      );

      await SupabaseProfileService.upsertUserRole(userId: uid, roleName: 'PATIENT');

      _otpAlreadySentForEmail = null;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
      }
    } catch (e, st) {
      debugPrint('savePatientProfileToSupabase: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save profile: $e')),
        );
      }
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Sends email OTP (creates auth user if needed), then opens verify screen; after OTP,
  /// [VerifyEmailView] calls [savePatientProfileToSupabase]. If already signed in as this email, saves immediately.
  Future<void> submitRegistration(BuildContext context) async {
    if (!isFormValid) return;

    isLoading = true;
    notifyListeners();

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final targetEmail = email?.trim() ?? '';
      if (targetEmail.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email is missing. Go back and try again.')),
          );
        }
        return;
      }

      if (session != null &&
          session.user.email?.toLowerCase() == targetEmail.toLowerCase()) {
        await savePatientProfileToSupabase(context);
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

      PendingRegistration.completePatientProfileAfterOtp = true;

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
      PendingRegistration.completePatientProfileAfterOtp = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessageForAuthException(e, flow: AuthFlow.signup)),
          ),
        );
      }
    } catch (e) {
      PendingRegistration.completePatientProfileAfterOtp = false;
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

  void disposeControllers() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    genderController.dispose();
    dobController.dispose();
    locationController.dispose();
  }
}
