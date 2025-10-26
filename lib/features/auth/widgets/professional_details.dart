import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/text_field.dart';

import '../registration/controller/doctor_registration_provider.dart';

class ProfessionalDetailsStep extends StatelessWidget {
  const ProfessionalDetailsStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorRegistrationProvider>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: "Professional Details",
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

          // 🔽 Specialization dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.black),
            ),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              hint: const Text("Select Specialization"),
              value: provider.specialization.text.isEmpty
                  ? null
                  : provider.specialization.text,
              items: provider.specializationOptions
                  .map(
                    (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s),
                ),
              )
                  .toList(),
              onChanged: (value) {
                provider.specialization.text = value ?? "";
              },
            ),
          ),

          const SizedBox(height: 16),
          CustomTextField(
            hintText: "Years of Experience",
            controller: provider.experience,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 24),
          CustomText(
            text: "Upload Certificate / License",
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
          const SizedBox(height: 8),
          _buildFilePicker(
            label: "Select File",
            fileName: provider.certificateFile?.name,
            onTap: () => provider.pickFile("certificate"),
          ),

          const SizedBox(height: 24),
          CustomText(
            text: "National ID Card",
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildFilePicker(
                  label: "Front Side",
                  fileName: provider.idFrontFile?.name,
                  onTap: () => provider.pickFile("idFront"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilePicker(
                  label: "Back Side",
                  fileName: provider.idBackFile?.name,
                  onTap: () => provider.pickFile("idBack"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
          CustomButton(
            text: "Continue",
            onPressed: provider.specialization.text.isNotEmpty &&
                provider.certificateFile != null &&
                provider.idFrontFile != null &&
                provider.idBackFile != null
                ? provider.nextStep
                : null,
            backgroundColor:
            provider.specialization.text.isNotEmpty &&
                provider.certificateFile != null &&
                provider.idFrontFile != null &&
                provider.idBackFile != null
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePicker({
    required String label,
    required VoidCallback onTap,
    String? fileName,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.black),
        ),
        child: Row(
          children: [
            const Icon(Icons.upload_file_outlined, color: AppColors.hintColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fileName ?? label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fileName != null
                      ? AppColors.textColor
                      : AppColors.hintColor,
                ),
              ),
            ),
            if (fileName != null)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }
}
