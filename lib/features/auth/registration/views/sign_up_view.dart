import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_sizing.dart';
import '../../../../shared_widgets/app_button.dart';
import '../../../../shared_widgets/custom_text.dart';
import '../../../../shared_widgets/text_field.dart';
import '../../otp_verification/views/otp_view.dart';

class CreateAccountView extends StatefulWidget {
  const CreateAccountView({Key? key}) : super(key: key);

  @override
  _CreateAccountViewState createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends State<CreateAccountView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreeTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(Icons.arrow_back_outlined,
                              color: AppColors.textColor, size: 24),
                        ),
                        kGap16,
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
                        CustomTextField(
                          label: 'Email Address',
                          hintText: 'Email Address',
                          controller: _emailController,
                          prefixIcon: Icon(Icons.email_outlined,
                              color: AppColors.hintColor, size: 20),
                        ),
                        kGap16,
                        CustomTextField(
                          label: 'Create Password',
                          hintText: 'Create Password',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          prefixIcon: Icon(Icons.lock_outline,
                              color: AppColors.hintColor, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.hintColor,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        kGap16,
                        CustomTextField(
                          label: 'Confirm Password',
                          hintText: 'Confirm Password',
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          prefixIcon: Icon(Icons.lock_outline,
                              color: AppColors.hintColor, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.hintColor,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              });
                            },
                          ),
                        ),
                        kGap20,
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreeTerms = value ?? false;
                                });
                              },
                              activeColor: AppColors.primary,
                            ),
                            Expanded(
                              child: Wrap(
                                children: [
                                  CustomText(
                                    text: 'I agree to the ',
                                    color: AppColors.textColor,
                                  ),
                                  CustomText(
                                    text: 'Terms of Use',
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  CustomText(
                                    text: ' and ',
                                    color: AppColors.textColor,
                                  ),
                                  CustomText(
                                    text: 'Privacy Policy',
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  CustomText(
                                    text: '.',
                                    color: AppColors.textColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(), // ✅ works now because Column has bounded height via IntrinsicHeight
                        CustomButton(
                          text: 'Create Account',
                          onPressed: _agreeTerms
                              ? () {
                            Get.to(VerifyEmailView());
                            // TODO: Handle create account
                          }
                              : null,
                          backgroundColor: _agreeTerms
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(.5),
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
