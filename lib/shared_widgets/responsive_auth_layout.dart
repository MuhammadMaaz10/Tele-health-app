import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_images.dart';
import '../core/utils/app_sizing.dart';
import 'custom_text.dart';

class ResponsiveAuthLayout extends StatelessWidget {
  final Widget formContent;
  final String? title;
  final String? description;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const ResponsiveAuthLayout({
    Key? key,
    required this.formContent,
    this.title,
    this.description,
    this.showBackButton = false,
    this.onBackPressed,
  }) : super(key: key);

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
                      text: title ?? 'Welcome to Telehealth Services',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColor,
                      textAlign: TextAlign.center,
                    ),
                    if (description != null) ...[
                      kGap20,
                      CustomText(
                        text: description!,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textColor.withOpacity(0.7),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                      ),
                    ] else ...[
                      kGap20,
                      CustomText(
                        text: 'Your trusted platform for seamless healthcare management. Connect with healthcare professionals and manage your health journey with ease.',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textColor.withOpacity(0.7),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                      ),
                    ],
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
        // Right Section - Form Content
        Expanded(
          flex: 1,
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showBackButton)
                        GestureDetector(
                          onTap: onBackPressed ?? () => Navigator.pop(context),
                          child: Icon(
                            Icons.arrow_back_outlined,
                            color: AppColors.textColor,
                            size: 24,
                          ),
                        ),
                      if (showBackButton) kGap20,
                      formContent,
                    ],
                  ),
                ),
              ),
            ),
          ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showBackButton)
                    GestureDetector(
                      onTap: onBackPressed ?? () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back_outlined,
                        color: AppColors.textColor,
                        size: 24,
                      ),
                    ),
                  if (showBackButton) kGap16,
                  Center(
                    child: Container(
                      width: isTablet ? 200 : 180,
                      height: isTablet ? 200 : 180,
                      color: Colors.transparent,
                      child: Image.asset(AppImages.logo),
                    ),
                  ),
                  kGap40,
                  formContent,
                ],
              ),
            ),
          );
        },
      ),
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
}

