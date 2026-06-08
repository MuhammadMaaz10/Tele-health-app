import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/text_field.dart';
import 'package:telehealth_app/shared_widgets/responsive_auth_layout.dart';
import '../controller/patient_profile_provider.dart';

class PatientRegistrationView extends StatelessWidget {
  final String email;
  final String role;

  const PatientRegistrationView({
    Key? key,
    required this.email,
    required this.role,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

  const _CompleteProfileBody({
    Key? key,
    required this.email,
    required this.role,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProfileProvider>();

    return ResponsiveAuthLayout(
      title: 'Complete Your Profile',
      description:
      'Fill in your details to complete your profile and start using our telehealth services.',
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

            // ---------------------------------------------
            // Profile Picture
            // ---------------------------------------------
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
                      ? Icon(Icons.camera_alt_outlined,
                      size: 30, color: Colors.grey)
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

            // ---------------------------------------------
            // Text Fields
            // ---------------------------------------------
            _field(
              context,
              "First Name",
              controller: provider.firstNameController,
            ),
            _field(
              context,
              "Last Name",
              controller: provider.lastNameController,
            ),
            _field(
              context,
              "Phone Number",
              keyboardType: TextInputType.phone,
              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.hintColor),
              controller: provider.phoneController,
            ),

            _field(
              context,
              "Gender",
              readOnly: true,
              suffixIcon: const Icon(Icons.arrow_drop_down),
              controller: provider.genderController,
              onTap: () async {
                final gender = await showModalBottomSheet<String>(
                  context: context,
                  builder: (_) => const GenderPickerSheet(),
                );
                if (gender != null) {
                  provider.genderController.text = gender;
                  provider.notifyFormChange();
                }
              },
            ),

            _field(
              context,
              "Date of Birth",
              readOnly: true,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
              controller: provider.dobController,
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
                  provider.notifyFormChange();
                }
              },
            ),

            // ---------------------------------------------
            // Location Field
            // ---------------------------------------------
            _locationField(context, provider),

            kGap20,

            // ---------------------------------------------
            // ID Document
            // ---------------------------------------------
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
                child: provider.idDocument != null ||
                    provider.idDocumentBytes != null
                    ? Center(
                  child: CustomText(
                    text: "✅ Document Selected",
                    color: AppColors.primary,
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file_outlined, color: Colors.grey),
                    SizedBox(height: 6),
                    CustomText(
                      text: "Tap to upload file",
                      color: AppColors.hintColor,
                    ),
                  ],
                ),
              ),
            ),

            kGap30,

            // ---------------------------------------------
            // Submit Button
            // ---------------------------------------------
            CustomButton(
              text: "Complete Profile",
              isLoading: provider.isLoading,
              onPressed: provider.isFormValid && !provider.isLoading
                  ? () async {
                      await provider.submitRegistration(context);
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

  // ---------------------------------------------------------
  // FIELD BUILDER
  // ---------------------------------------------------------
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
    final provider = context.read<PatientProfileProvider>();

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
        onChanged: (_) => provider.notifyFormChange(),
      ),
    );
  }

  // ---------------------------------------------------------
  // LOCATION FIELD
  // ---------------------------------------------------------
  Widget _locationField(
      BuildContext context, PatientProfileProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextField(
        hintText: "Your Location",
        controller: provider.locationController,
        prefixIcon:
        Icon(Icons.location_on_outlined, color: AppColors.hintColor),
        suffixIcon: provider.isLoadingLocation
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : IconButton(
          icon: Icon(Icons.my_location_outlined,
              color: AppColors.primary),
          onPressed: () async {
            await provider.getCurrentLocation();
          },
        ),
        onChanged: (_) => provider.notifyFormChange(),
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
