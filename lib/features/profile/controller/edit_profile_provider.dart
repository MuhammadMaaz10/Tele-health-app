import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:telehealth_app/core/supabase/supabase_profile_service.dart';
import '../model/profile_model.dart' as pm;

class EditProfileProvider extends ChangeNotifier {

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

  void initializeFromUser(pm.User user, String role, String email) {
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
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('Not signed in');
      }

      final emailToSend = userEmail ?? '';
      if (emailToSend.isEmpty) {
        throw Exception('Email is required but not available');
      }

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

      Future<String?> uploadDoc(PlatformFile? f, String fallbackName) async {
        if (f == null) return null;
        final bytes = f.bytes ?? (f.path != null ? await File(f.path!).readAsBytes() : null);
        if (bytes == null) return null;
        return SupabaseProfileService.uploadBytesForUser(
          uid: uid,
          bucket: 'documents',
          bytes: bytes,
          filename: f.name.isNotEmpty ? f.name : fallbackName,
        );
      }

      final idPath = await uploadDoc(idDocumentFile, 'id.pdf');
      final medPath = (userRole == 'DOCTOR' || userRole == 'NURSE')
          ? await uploadDoc(medicalCertificateFile, 'medical.pdf')
          : null;
      final eduPath = (userRole == 'DOCTOR' || userRole == 'NURSE')
          ? await uploadDoc(educationalCertificateFile, 'edu.pdf')
          : null;

      final dob = dobController.text.trim().isNotEmpty
          ? SupabaseProfileService.parseDobDayFirst(dobController.text.trim())
          : null;
      final dobStr = dob != null
          ? '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}'
          : null;

      final fields = <String, dynamic>{'email': emailToSend};
      if (usernameController.text.trim().isNotEmpty) {
        fields['username'] = usernameController.text.trim();
      }
      if (phoneController.text.trim().isNotEmpty) {
        fields['phone'] = phoneController.text.trim();
      }
      if (genderController.text.trim().isNotEmpty) {
        fields['gender'] = genderController.text.trim().toLowerCase();
      }
      if (dobStr != null) fields['dob'] = dobStr;
      if (latitude != null) fields['latitude'] = latitude;
      if (longitude != null) fields['longitude'] = longitude;
      if ((userRole == 'DOCTOR' || userRole == 'NURSE') &&
          specializationController.text.trim().isNotEmpty) {
        fields['specialization'] = specializationController.text.trim();
      }
      if (profileUrl != null) fields['profile_pic_url'] = profileUrl;
      if (idPath != null) fields['id_document_url'] = idPath;
      if (medPath != null) fields['medical_certificate_url'] = medPath;
      if (eduPath != null) fields['educational_certificate_url'] = eduPath;

      await SupabaseProfileService.updateProfileRow(userId: uid, fields: fields);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully ✅")),
        );
      }
    } catch (e) {
      error = 'Failed to update profile. Please try again.';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error ($e)')),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
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

