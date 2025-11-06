import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/text_field.dart';

import '../registration/controller/doctor_registration_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/text_field.dart';
import '../registration/controller/doctor_registration_provider.dart';

class BasicInfoStep extends StatelessWidget {
  const BasicInfoStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorRegistrationProvider>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: "Basic Information",
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textColor,
          ),
          const SizedBox(height: 6),
          CustomText(
            text: "Fill in the details to continue",
            color: AppColors.hintColor,
          ),
          const SizedBox(height: 24),

          CustomTextField(
            hintText: "First Name",
            controller: provider.firstName,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            hintText: "Last Name",
            controller: provider.lastName,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            hintText: "Phone Number",
            controller: provider.phone,
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            hintText: "Medical Practice Number",
            controller: provider.practiceNumber,
          ),
          const SizedBox(height: 16),

          // 🩺 Role Picker (Doctor / Nurse)
          CustomTextField(
            hintText: "Role (Doctor / Nurse)",
            controller: provider.role,
            readOnly: true,
            suffixIcon: const Icon(Icons.arrow_drop_down),
            onTap: () async {
              final role = await showModalBottomSheet<String>(
                context: context,
                builder: (_) => const RolePickerSheet(),
              );
              if (role != null) provider.role.text = role;
            },
          ),
          const SizedBox(height: 16),

          // 🎂 Date of Birth Picker
          CustomTextField(
            hintText: "Date of Birth",
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
                "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
              }
            },
          ),
          const SizedBox(height: 16),

          // 🚻 Gender Picker
          CustomTextField(
            hintText: "Gender",
            controller: provider.gender,
            readOnly: true,
            suffixIcon: const Icon(Icons.arrow_drop_down),
            onTap: () async {
              final gender = await showModalBottomSheet<String>(
                context: context,
                builder: (_) => const GenderPickerSheet(),
              );
              if (gender != null) provider.gender.text = gender;
            },
          ),
          const SizedBox(height: 16),

          // 📍 Location Field
          CustomTextField(
            hintText: "Your Location",
            controller: provider.location,
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: provider.isLoadingLocation
                ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : IconButton(
              icon: const Icon(Icons.my_location_outlined),
              onPressed: provider.getCurrentLocation,
            ),
          ),

          const SizedBox(height: 40),
          CustomButton(
            text: "Continue",
            onPressed: provider.firstName.text.isNotEmpty &&
                provider.lastName.text.isNotEmpty &&
                provider.phone.text.isNotEmpty &&
                provider.role.text.isNotEmpty &&
                provider.dob.text.isNotEmpty
                ? provider.nextStep
                : null,
            backgroundColor: (provider.firstName.text.isNotEmpty &&
                provider.lastName.text.isNotEmpty &&
                provider.phone.text.isNotEmpty &&
                provider.role.text.isNotEmpty &&
                provider.dob.text.isNotEmpty)
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.5),
          ),
        ],
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

class RolePickerSheet extends StatelessWidget {
  const RolePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final roles = ["Doctor", "Nurse"];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: roles
            .map(
              (r) => ListTile(
            title: Text(r),
            onTap: () => Navigator.pop(context, r),
          ),
        )
            .toList(),
      ),
    );
  }
}
