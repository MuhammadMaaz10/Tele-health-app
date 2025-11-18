import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import '../registration/controller/doctor_registration_provider.dart';
import '../otp_verification/views/otp_view.dart';

class PendingApprovalStep extends StatelessWidget {
  final String email;
  final String role;
  
  const PendingApprovalStep({Key? key, required this.email, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorRegistrationProvider>();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.primary, size: 70),
            const SizedBox(height: 20),
            CustomText(
              text: "Complete Registration",
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textColor,
            ),
            const SizedBox(height: 8),
            CustomText(
              text:
              "Click finish to complete your registration and verify your email.",
              textAlign: TextAlign.center,
              color: AppColors.hintColor,
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: provider.isLoading ? "Submitting..." : "Finish",
              isLoading: provider.isLoading,
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      try {
                        await provider.submitRegistration(context);
                        // Navigate to OTP verification for registration
                        Get.to(() => VerifyEmailView(email: email, isRegistration: true));
                      } catch (e) {
                        // Error already shown in submitRegistration
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
