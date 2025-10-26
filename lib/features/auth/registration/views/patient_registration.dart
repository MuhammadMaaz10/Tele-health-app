import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/features/auth/login/controller/login_controller.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/text_field.dart';
import '../controller/patient_profile_provider.dart';


class PatientRegistrationView extends StatelessWidget {
  const PatientRegistrationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const _CompleteProfileBody();
  }
}

class _CompleteProfileBody extends StatelessWidget {
  const _CompleteProfileBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProfileProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                _field(context, "First Name", "firstName",
                    controller: provider.firstNameController),
                _field(context, "Last Name", "lastName",
                    controller: provider.lastNameController),
                _field(context, "Phone Number", "phone",
                    controller: provider.phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon:
                    Icon(Icons.phone_outlined, color: AppColors.hintColor)),
                _field(context, "Age", "age",
                    controller: provider.ageController,
                    keyboardType: TextInputType.number),

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

                kGap30,
                CustomText(
                    text: "Next of Kin",
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor),
                kGap16,

                _field(context, "Name", "kinName",
                    controller: provider.kinNameController),
                _field(context, "Surname", "kinSurname",
                    controller: provider.kinSurnameController),
                _field(context, "Phone Number", "kinPhone",
                    controller: provider.kinPhoneController,
                    keyboardType: TextInputType.phone),

                kGap30,
                CustomButton(
                  text: "Complete Profile",
                  onPressed: provider.isFormValid
                      ? () => provider.handleSubmit(context)
                      : null,
                  backgroundColor: provider.isFormValid
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.5),
                ),
              ],
            ),
          ),
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
                  fontSize: 12),
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
              onPressed: provider.getCurrentLocation,
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
