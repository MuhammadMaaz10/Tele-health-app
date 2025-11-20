import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/utils/app_images.dart';
import 'package:telehealth_app/features/auth/login/controller/login_controller.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_sizing.dart';
import '../../../../shared_widgets/text_field.dart';
import '../../registration/views/sign_up_view.dart';
import '../../otp_verification/views/otp_view.dart';
import '../../../../shared_widgets/app_button.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout(context)
            : _buildMobileTabletLayout(context, isTablet),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left Section - Logo and Content
        Expanded(
          flex: 1,
          child: Container(
            color: AppColors.primary.withOpacity(0.05),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      color: Colors.transparent,
                      child: Image.asset(AppImages.logo),
                    ),
                    kGap40,
                    CustomText(
                      text: 'Welcome to Telehealth Services',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColor,
                      textAlign: TextAlign.center,
                    ),
                    kGap20,
                    CustomText(
                      text: 'Your trusted platform for seamless healthcare management. Connect with healthcare professionals and manage your health journey with ease.',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textColor.withOpacity(0.7),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                    ),
                    kGap40,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFeatureItem(Icons.verified_user, 'Secure'),
                        kGap30,
                        _buildFeatureItem(Icons.access_time, '24/7 Support'),
                        kGap30,
                        _buildFeatureItem(Icons.medical_services, 'Expert Care'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right Section - Login Form
        Expanded(
          flex: 1,
          child: _buildLoginForm(context),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 32),
        kGap10,
        CustomText(
          text: text,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textColor,
        ),
      ],
    );
  }

  Widget _buildMobileTabletLayout(BuildContext context, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 40 : 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Consumer<LoginProvider>(
                builder: (context, provider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      kGap32,
                      Center(
                        child: Container(
                          width: isTablet ? 200 : 180,
                          height: isTablet ? 200 : 180,
                          color: Colors.transparent,
                          child: Image.asset(AppImages.logo),
                        ),
                      ),
                      kGap40,
                      _buildLoginFormContent(context, provider, isTablet, false),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Consumer<LoginProvider>(
      builder: (context, provider, child) {
        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _buildLoginFormContent(context, provider, false, true),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginFormContent(BuildContext context, LoginProvider provider, bool isTablet, [bool isDesktop = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: 'Login',
          fontSize: isTablet ? 28 : 22,
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
          isLoading: provider.isLoading,
          text: 'Continue',
          onPressed: provider.isFormValid && !provider.isLoading
              ? () async {
                  final success = await provider.sendOtp();
                  if (success) {
                    Get.to(() => VerifyEmailView(email: provider.emailController.text.trim(),));
                  }
                }
              : null,
          backgroundColor: provider.isFormValid && !provider.isLoading
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.5),
        ),
      ],
    );
  }
}
