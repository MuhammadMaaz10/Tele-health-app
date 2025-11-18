import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/text_field.dart';
import 'package:telehealth_app/shared_widgets/responsive_auth_layout.dart';
import '../controller/doctor_registration_provider.dart';
import '../../otp_verification/views/otp_view.dart';

class DoctorRegistrationViewNew extends StatelessWidget {
  final String email;
  final String role;
  
  const DoctorRegistrationViewNew({Key? key, required this.email, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = DoctorRegistrationProvider();
        provider.setEmail(email);
        provider.setRole(role);
        return provider;
      },
      child: _CompleteProfileBody(email: email, role: role),
    );
  }
}

class _CompleteProfileBody extends StatelessWidget {
  final String email;
  final String role;
  
  const _CompleteProfileBody({Key? key, required this.email, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorRegistrationProvider>();

    return ResponsiveAuthLayout(
      title: 'Complete Your Profile',
      description: 'Fill in your details to complete your profile and start using our telehealth services.',
      showBackButton: true,
      formContent: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // --- Profile Picture Upload ---
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
                  child: provider.profileImage == null && provider.profileImageBytes == null
                      ? Icon(Icons.camera_alt_outlined, size: 30, color: Colors.grey)
                      : null,
                ),

              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: CustomText(
                text: "Tap to upload profile picture (optional)",
                fontSize: 13,
                color: AppColors.hintColor,
              ),
            ),

            const SizedBox(height: 24),
            _field(context, "Username", controller: provider.username),
            _field(context, "Phone Number", controller: provider.phone,
                keyboardType: TextInputType.phone,
                prefixIcon: Icon(Icons.phone_outlined, color: AppColors.hintColor)),
            // _field(context, "Password", controller: provider.password,
            //     obscureText: true,
            //     prefixIcon: Icon(Icons.lock_outline, color: AppColors.hintColor)),

            _field(
              context,
              "Gender",
              controller: provider.gender,
              readOnly: true,
              suffixIcon: const Icon(Icons.arrow_drop_down),
              onTap: () async {
                final gender = await showModalBottomSheet<String>(
                  context: context,
                  builder: (_) => const GenderPickerSheet(),
                );
                if (gender != null) {
                  provider.gender.text = gender;
                  provider.notifyFormChange();
                }
              },
            ),

            _field(
              context,
              "Date of Birth",
              controller: provider.dob,
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
                  provider.dob.text =
                  "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
                  provider.notifyFormChange();
                }
              },
            ),

            // Location button - required for registration
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CustomButton(
                text: provider.latitude != null && provider.longitude != null
                    ? "Location Captured ✓"
                    : "Get Current Location",
                isLoading: provider.isLoadingLocation,
                onPressed: provider.isLoadingLocation
                    ? null
                    : () async {
                        await provider.getCurrentLocation();
                        provider.notifyFormChange();
                      },
                backgroundColor: provider.latitude != null && provider.longitude != null
                    ? Colors.green
                    : AppColors.primary,
              ),
            ),

            kGap20,
            CustomText(
                text: "Professional Details",
                fontWeight: FontWeight.w600,
                color: AppColors.textColor),
            kGap16,

            // Specialization dropdown
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
                  value: provider.specialization.text.isEmpty
                      ? null
                      : provider.specialization.text,
                  items: provider.specializationOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) {
                    provider.specialization.text = value ?? "";
                    provider.notifyFormChange();
                  },
                ),
              ),
            ),

            kGap20,
            CustomText(
                text: "Documents",
                fontWeight: FontWeight.w600,
                color: AppColors.textColor),
            kGap16,

            // ID Document Upload
            _buildFileUpload(
              context,
              "Upload ID Document",
              provider.idDocumentFile?.name,
              () => provider.pickFile("idDocument"),
            ),

            const SizedBox(height: 16),

            // Medical Certificate Upload
            _buildFileUpload(
              context,
              "Upload Medical Certificate",
              provider.practicingCertificateFile?.name,
              () => provider.pickFile("practicingCertificate"),
            ),

            const SizedBox(height: 16),

            // Educational Certificate Upload (Required)
            _buildFileUpload(
              context,
              "Upload Educational Certificate",
              provider.educationalCertificateFile?.name,
              () => provider.pickFile("educationalCertificate"),
            ),

            kGap30,
            CustomButton(
              text: "Complete Profile",
              isLoading: provider.isLoading,
              onPressed: provider.isFormValid && !provider.isLoading
                  ? () async {
                      try {
                        await provider.submitRegistration(context);
                        // Navigate to OTP verification for registration
                        Get.to(() => VerifyEmailView(email: email, isRegistration: true));
                      } catch (e) {
                        // Error already shown in submitRegistration
                      }
                    }
                  : null,
              backgroundColor: provider.isFormValid && !provider.isLoading
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
      BuildContext context,
      String label, {
        required TextEditingController controller,
        TextInputType? keyboardType,
        bool readOnly = false,
        bool obscureText = false,
        Widget? prefixIcon,
        Widget? suffixIcon,
        VoidCallback? onTap,
      }) {
    final provider = context.watch<DoctorRegistrationProvider>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextField(
        label: label,
        hintText: label,
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        obscureText: obscureText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        onTap: onTap,
        onChanged: (value) => provider.notifyFormChange(),
      ),
    );
  }


  Widget _buildFileUpload(
      BuildContext context,
      String label,
      String? fileName,
      VoidCallback onTap,
      ) {
    final provider = context.watch<DoctorRegistrationProvider>();
    return GestureDetector(
      onTap: () {
        onTap();
        // Small delay to ensure file is picked before checking form validity
        Future.delayed(const Duration(milliseconds: 100), () {
          provider.notifyFormChange();
        });
      },
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
  const GenderPickerSheet({Key? key}) : super(key: key);

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

