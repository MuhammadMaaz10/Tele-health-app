import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_sizing.dart';
import '../../../../shared_widgets/app_button.dart';
import '../../../../shared_widgets/custom_text.dart';
import '../../../../shared_widgets/text_field.dart';
import '../../../../shared_widgets/responsive_auth_layout.dart';
import '../controller/sign_up_provider.dart';
import '../../registration/views/patient_registration.dart';
import '../../registration/views/doctor_registration_new.dart';
import '../../otp_verification/views/otp_view.dart';

class CreateAccountView extends StatelessWidget {
  const CreateAccountView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveAuthLayout(
      title: 'Create Your Account',
      description: 'Join our telehealth platform and start your journey towards better healthcare management.',
      showBackButton: true,
      formContent: Consumer<SignUpProvider>(
        builder: (context, provider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: 'Create New Account',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textColor,
              ),
              kGap8,
              Row(
                children: [
                  CustomText(
                    text: 'Already have an account?',
                    color: AppColors.textColor,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: CustomText(
                      text: ' Login',
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              kGap30,
              
              // Role Selection
              CustomText(
                text: 'Select Role',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
              kGap12,
              Row(
                children: [
                  Expanded(
                    child: _buildRoleOption(
                      context,
                      provider,
                      'PATIENT',
                      Icons.person_outline,
                    ),
                  ),
                  kGap12,
                  Expanded(
                    child: _buildRoleOption(
                      context,
                      provider,
                      'DOCTOR',
                      Icons.medical_services_outlined,
                    ),
                  ),
                  kGap12,
                  Expanded(
                    child: _buildRoleOption(
                      context,
                      provider,
                      'NURSE',
                      Icons.local_hospital_outlined,
                    ),
                  ),
                ],
              ),
              
              kGap24,
              
              // Email Field
              CustomTextField(
                label: 'Email Address',
                hintText: 'Email Address',
                controller: provider.emailController,
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: AppColors.hintColor,
                  size: 20,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              
              if (provider.error != null) ...[
                kGap8,
                CustomText(
                  text: provider.error!,
                  color: Colors.red,
                  fontSize: 12,
                ),
              ],
              
              kGap40,
              
              CustomButton(
                text: 'Continue',
                isLoading: provider.isLoading,
                onPressed: provider.isFormValid && !provider.isLoading
                    ? () => _handleContinue(context, provider)
                    : null,
                backgroundColor: provider.isFormValid && !provider.isLoading
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.5),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleOption(
    BuildContext context,
    SignUpProvider provider,
    String role,
    IconData icon,
  ) {
    final isSelected = provider.selectedRole == role;
    return GestureDetector(
      onTap: () => provider.setRole(role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.hintColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.hintColor,
              size: 28,
            ),
            kGap8,
            CustomText(
              text: role,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.primary : AppColors.textColor,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContinue(BuildContext context, SignUpProvider provider) async {
    final response = await provider.checkUser();
    if (response == null) return;

    final data = response['data'] as Map<String, dynamic>?;

    final status = data?['status'] as String?;
    final backendMessage = data?['message'] as String?;
    final email = provider.emailController.text.trim();
    final role = provider.selectedRole!.toUpperCase();

    // 1️⃣ If email already EXISTS
    if (status == 'EXISTS') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(backendMessage ?? "User already registered. Redirect to login."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 2️⃣ If account INACTIVE → Send to OTP verification
    if (status == 'INACTIVE') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(backendMessage ?? "Account inactive. OTP sent."),
          backgroundColor: Colors.blue,
        ),
      );

      // Navigate to OTP screen for reactivation
      Get.to(() => VerifyEmailView(
        email: email,
        isRegistration: true, // important
      ));
      return;
    }

    // 3️⃣ If NEW → continue to registration
    if (role == 'PATIENT') {
      Get.to(() => PatientRegistrationView(email: email, role: role));
    } else {
      Get.to(() => DoctorRegistrationViewNew(email: email, role: role));
    }
  }

}
