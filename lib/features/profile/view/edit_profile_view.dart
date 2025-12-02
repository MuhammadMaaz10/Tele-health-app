import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/text_field.dart';
import 'package:telehealth_app/shared_widgets/responsive_auth_layout.dart';
import '../controller/edit_profile_provider.dart';
import '../controller/profile_provider.dart';

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveAuthLayout(
      title: 'Edit Profile',
      description: 'Update your profile information',
      showBackButton: true,
      formContent: Consumer<EditProfileProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: "Edit Profile",
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColor,
                ),
                kGap8,
                CustomText(
                  text: "Update your information below",
                  color: AppColors.hintColor,
                ),
                kGap30,

                // Profile Picture
                Center(
                  child: GestureDetector(
                    onTap: () => provider.pickProfileImage(context),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: provider.profileImage != null
                          ? FileImage(provider.profileImage!)
                          : provider.profileImageBytes != null
                              ? MemoryImage(provider.profileImageBytes!)
                              : null,
                      child: provider.profileImage == null &&
                              provider.profileImageBytes == null
                          ? const Icon(Icons.camera_alt_outlined,
                              size: 30, color: Colors.grey)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: CustomText(
                    text: "Tap to change profile picture",
                    fontSize: 13,
                    color: AppColors.hintColor,
                  ),
                ),

                const SizedBox(height: 24),

                // Username
                _field(
                  context,
                  "Username",
                  controller: provider.usernameController,
                ),

                // Phone
                _field(
                  context,
                  "Phone Number",
                  controller: provider.phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icon(Icons.phone_outlined, color: AppColors.hintColor),
                ),

                // Gender
                _field(
                  context,
                  "Gender",
                  controller: provider.genderController,
                  readOnly: true,
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  onTap: () async {
                    final gender = await showModalBottomSheet<String>(
                      context: context,
                      builder: (_) => const GenderPickerSheet(),
                    );
                    if (gender != null) {
                      provider.genderController.text = gender;
                    }
                  },
                ),

                // Date of Birth
                _field(
                  context,
                  "Date of Birth",
                  controller: provider.dobController,
                  readOnly: true,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final now = DateTime.now();
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime(now.year - 25),
                      firstDate: DateTime(1900),
                      lastDate: now,
                    );
                    if (pickedDate != null) {
                      provider.dobController.text =
                          "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
                    }
                  },
                ),

                // Location
                _locationField(context, provider),

                // Specialization (for Doctor/Nurse only)
                if (provider.userRole == 'DOCTOR' || provider.userRole == 'NURSE') ...[
                  kGap20,
                  CustomText(
                    text: "Professional Details",
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                  kGap16,
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.black),
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: "Specialization",
                        ),
                        value: provider.specializationController.text.isEmpty
                            ? null
                            : provider.specializationController.text,
                        items: provider.specializationOptions
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (value) {
                          provider.specializationController.text = value ?? "";
                        },
                      ),
                    ),
                  ),
                ],

                // Documents Section
                kGap20,
                CustomText(
                  text: "Documents (Optional)",
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
                kGap16,

                // ID Document
                _buildFileUpload(
                  context,
                  "Update ID Document",
                  provider.idDocumentFile?.name,
                  () => provider.pickFile("idDocument"),
                ),

                const SizedBox(height: 16),

                // Medical Certificate (Doctor/Nurse only)
                if (provider.userRole == 'DOCTOR' || provider.userRole == 'NURSE') ...[
                  _buildFileUpload(
                    context,
                    "Update Medical Certificate",
                    provider.medicalCertificateFile?.name,
                    () => provider.pickFile("medicalCertificate"),
                  ),
                  const SizedBox(height: 16),
                  _buildFileUpload(
                    context,
                    "Update Educational Certificate",
                    provider.educationalCertificateFile?.name,
                    () => provider.pickFile("educationalCertificate"),
                  ),
                  const SizedBox(height: 16),
                ],

                kGap30,

                // Update Button
                CustomButton(
                  text: "Update Profile",
                  isLoading: provider.isLoading,
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          await provider.updateProfile(context);
                          if (context.mounted && !provider.isLoading && provider.error == null) {
                            // Refresh profile
                            try {
                              final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
                              await profileProvider.loadProfile();
                            } catch (e) {
                              debugPrint('Could not refresh profile: $e');
                            }
                            if (context.mounted) {
                              Get.back();
                            }
                          }
                        },
                  backgroundColor: provider.isLoading
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.primary,
                ),

                if (provider.error != null) ...[
                  kGap16,
                  CustomText(
                    text: provider.error!,
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _field(
    BuildContext context,
    String label, {
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool readOnly = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextField(
        label: label,
        hintText: label,
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        onTap: onTap,
      ),
    );
  }

  Widget _locationField(BuildContext context, EditProfileProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextField(
        hintText: "Your Location",
        controller: provider.locationController,
        prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.hintColor),
        suffixIcon: provider.isLoadingLocation
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: Icon(Icons.my_location_outlined, color: AppColors.primary),
                onPressed: () async {
                  await provider.getCurrentLocation();
                },
              ),
      ),
    );
  }

  Widget _buildFileUpload(
    BuildContext context,
    String label,
    String? fileName,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: fileName != null
            ? Center(
                child: CustomText(
                  text: "✅ $fileName",
                  color: AppColors.primary,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_file_outlined, color: Colors.grey),
                  const SizedBox(height: 6),
                  CustomText(
                    text: label,
                    color: AppColors.hintColor,
                  ),
                ],
              ),
      ),
    );
  }
}

class GenderPickerSheet extends StatelessWidget {
  const GenderPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final genders = ["Male", "Female", "Other"];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: genders
            .map((g) => ListTile(
                  title: Text(g),
                  onTap: () => Navigator.pop(context, g),
                ))
            .toList(),
      ),
    );
  }
}

