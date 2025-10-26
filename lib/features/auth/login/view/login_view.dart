import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:telehealth_app/core/utils/app_images.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_sizing.dart';
import '../../../../shared_widgets/text_field.dart';
import '../../forgot_password/view/fotgot_password.dart';
import '../../registration/views/doctor_registration.dart';
import '../../registration/views/patient_registration.dart';
import '../../registration/views/sign_up_view.dart';
import '../../../../shared_widgets/app_button.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String selectedRole = 'User'; // Default login type

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        kGap32,
                        Center(
                          child: Container(
                            width: 180,
                            height: 180,
                            color: Colors.transparent,
                            child: Image.asset(AppImages.logo),
                          ),
                        ),
                        kGap40,

                        // Dynamic Login Title
                        CustomText(
                          text: selectedRole == 'User'
                              ? 'Login'
                              : '$selectedRole Login',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textColor,
                        ),
                        kGap10,

                        Row(
                          children: [
                            CustomText(
                              text: 'Not have an account?',
                              color: AppColors.textColor,
                            ),
                            GestureDetector(
                              onTap: () {
                                Get.to(CreateAccountView());
                              },
                              child: CustomText(
                                text: ' Create Account',
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),

                        kGap30,
                        CustomTextField(
                          label: 'Email Address',
                          hintText: 'Email Address',
                          controller: _emailController,
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: AppColors.hintColor,
                            size: 20,
                          ),
                        ),
                        kGap16,
                        CustomTextField(
                          label: 'Password',
                          hintText: 'Password',
                          controller: _passwordController,
                          obscureText: true,
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: AppColors.hintColor,
                          ),
                        ),
                        kGap20,

                        GestureDetector(
                          onTap: () {
                            Get.to(ForgotPasswordView());
                          },
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: CustomText(
                              text: 'Forget Password?',
                              fontWeight: FontWeight.w500,
                              color: AppColors.textColor,
                            ),
                          ),
                        ),

                        const Spacer(), // ✅ This pushes the button to the bottom

                        // ✅ Dynamic Button Text (uses your CustomButton)
                        CustomButton(
                          text: selectedRole == 'User'
                              ? 'Login'
                              : 'Login',
                          onPressed: () {
                            // Role-based login handling
                            if (selectedRole == 'Doctor') {
                              Get.to(DoctorRegistrationView());
                              // Doctor login logic
                            } else if (selectedRole == 'Nurse') {
                              // Nurse login logic
                            } else {
                              Get.to(PatientRegistrationView());
                              // User login logic
                            }
                          },
                          backgroundColor: AppColors.primary,
                        ),

                        kGap20,

                        // ✅ Role Switcher Row
                        IntrinsicHeight(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                text: 'or Login as? ',
                                color: AppColors.textColor,
                              ),

                              if (selectedRole != 'Doctor') ...[
                                GestureDetector(
                                  onTap: () => setState(() {
                                    selectedRole = 'Doctor';
                                  }),
                                  child: CustomText(
                                    text: 'Doctor',
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                                if (selectedRole != 'Nurse')
                                  VerticalDivider(
                                    color: AppColors.black,
                                    thickness: 1,
                                    width: 16,
                                  ),
                              ],

                              if (selectedRole != 'Nurse')
                                GestureDetector(
                                  onTap: () => setState(() {
                                    selectedRole = 'Nurse';
                                  }),
                                  child: CustomText(
                                    text: 'Nurse',
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),

                              if (selectedRole != 'User')
                                VerticalDivider(
                                  color: AppColors.black,
                                  thickness: 1,
                                  width: 16,
                                ),

                              if (selectedRole != 'User')
                                GestureDetector(
                                  onTap: () => setState(() {
                                    selectedRole = 'User';
                                  }),
                                  child: CustomText(
                                    text: 'User',
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
