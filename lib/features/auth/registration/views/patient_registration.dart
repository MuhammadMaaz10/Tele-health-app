import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/text_field.dart';
import 'package:telehealth_app/shared_widgets/responsive_auth_layout.dart';
import '../controller/patient_profile_provider.dart';
import '../../otp_verification/views/otp_view.dart';

class PatientRegistrationView extends StatelessWidget {
  final String email;
  final String role;
  
  const PatientRegistrationView({Key? key, required this.email, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Set email and role in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PatientProfileProvider>();
      provider.setEmail(email);
      provider.setRole(role);
    });
    return _CompleteProfileBody(email: email, role: role);
  }
}

class _CompleteProfileBody extends StatelessWidget {
  final String email;
  final String role;
  
  const _CompleteProfileBody({Key? key, required this.email, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProfileProvider>();

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
                _field(context, "First Name", "firstName",
                    controller: provider.firstNameController),
                _field(context, "Last Name", "lastName",
                    controller: provider.lastNameController),
                _field(context, "Phone Number", "phone",
                    controller: provider.phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon:
                    Icon(Icons.phone_outlined, color: AppColors.hintColor)),

                _field(
                  context,
                  "Gender",
                  "gender",
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
                      provider.errors["gender"] = null;
                      provider.notifyListeners();
                    }
                  },
                ),

                _field(
                  context,
                  "Date of Birth",
                  "dob",
                  controller: provider.dobController,
                  readOnly: true,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  onTap: () => provider.pickDate(context),
                ),

                _locationField(context, provider),

                // kGap20,

                CustomText(
                  text: "Upload ID Document (optional)",
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => provider.pickIdDocument(context),
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: provider.idDocument != null || provider.idDocumentBytes != null
                    ? Center(
                  child: CustomText(
                    text: "✅ ID Document Selected",
                    color: AppColors.primary,
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file_outlined, color: Colors.grey),
                    SizedBox(height: 6),
                    CustomText(text: "Tap to upload file", color: AppColors.hintColor),
                  ],
                ),

              ),
            ),


            kGap30,
            CustomButton(
              text: "Complete Profile",
              isLoading: provider.isLoading,
              onPressed: provider.isFormValid && !provider.isLoading
                  ? () async {
                      if (provider.handleSubmit(context)) {
                        try {
                          await provider.submitToApi(context);
                          // Navigate to OTP verification for registration
                          Get.to(() => VerifyEmailView(email: email, isRegistration: true));
                        } catch (e) {
                          // Error already shown in submitToApi
                        }
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
      String label,
      String key, {
        required TextEditingController controller,
        TextInputType? keyboardType,
        bool readOnly = false,
        Widget? prefixIcon,
        Widget? suffixIcon,
        VoidCallback? onTap,
      }) {
    final provider = context.watch<PatientProfileProvider>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: label,
            hintText: label,
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            onTap: onTap,
            onChanged: (v) => provider.validateField(key, v),
          ),
          if (provider.errors[key] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: CustomText(
                text: provider.errors[key]!,
                color: Colors.red,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _locationField(BuildContext context, PatientProfileProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            hintText: "Your Location",
            controller: provider.locationController,
            prefixIcon: Icon(Icons.location_on_outlined,
                color: AppColors.hintColor, size: 20),
            suffixIcon: provider.isLoadingLocation
                ? const SizedBox(
              width: 20,
              height: 20,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : IconButton(
              icon: Icon(Icons.my_location_outlined,
                  color: AppColors.primary, size: 20),
              onPressed: ()async{
               await provider.getCurrentLocation();
              },
            ),
            onChanged: (v) => provider.validateField("location", v),
          ),
          if (provider.errors["location"] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: CustomText(
                text: provider.errors["location"]!,
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          if (provider.locationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: CustomText(
                text: provider.locationError!,
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
        ],
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
