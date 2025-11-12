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
import '../../registration/views/doctor_registration.dart';
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
                      'Patient',
                      Icons.person_outline,
                    ),
                  ),
                  kGap12,
                  Expanded(
                    child: _buildRoleOption(
                      context,
                      provider,
                      'Doctor',
                      Icons.medical_services_outlined,
                    ),
                  ),
                  kGap12,
                  Expanded(
                    child: _buildRoleOption(
                      context,
                      provider,
                      'Nurse',
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
    
    if (response == null) {
      // Error already shown in provider
      return;
    }

    // Check if user already exists (backend will return a message)
    final message = response['message'] as String?;
    final userExists = response['exists'] as bool? ?? false;

    if (userExists) {
      // Show message from backend
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'User already registered'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // User doesn't exist, navigate to registration screen
    final role = provider.selectedRole!;
    final email = provider.emailController.text.trim();
    if (role == 'Patient') {
      Get.to(() => PatientRegistrationView(email: email));
    } else {
      // Doctor or Nurse
      Get.to(() => DoctorRegistrationView(email: email));
    }
  }
}
