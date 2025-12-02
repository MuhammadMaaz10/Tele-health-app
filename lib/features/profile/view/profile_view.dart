import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/features/auth/login/view/login_view.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import '../controller/profile_provider.dart';
import '../controller/edit_profile_provider.dart';
import '../model/profile_model.dart';
import 'edit_profile_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider(),
      child: const _ProfileViewBody(),
    );
  }
}

class _ProfileViewBody extends StatelessWidget {
  const _ProfileViewBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                ),
                onPressed: provider.user != null
                    ? () => _navigateToEditProfile(context, provider)
                    : null,
                tooltip: 'Edit Profile',
              );
            },
          ),
          Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
                        ),
                      )
                    : const Icon(
                        Icons.logout,
                        color: AppColors.error,
                      ),
                onPressed: provider.isLoading
                    ? null
                    : () => _handleLogout(context, provider),
                tooltip: 'Logout',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
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
        // Left Section - Profile Card
        Expanded(
          flex: 1,
          child: Container(
            color: AppColors.primary.withOpacity(0.05),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _buildProfileContent(context, true),
              ),
            ),
          ),
        ),
        // Right Section - Details
        Expanded(
          flex: 1,
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildProfileDetails(context, true),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabletLayout(BuildContext context, bool isTablet) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 40 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileContent(context, false),
            kGap30,
            _buildProfileDetails(context, false),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, bool isDesktop) {
    final provider = context.watch<ProfileProvider>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Profile Picture
        Container(
          width: isDesktop ? 150 : 120,
          height: isDesktop ? 150 : 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.1),
            border: Border.all(
              color: AppColors.primary,
              width: 3,
            ),
          ),
          child: provider.user?.profilePicUrl != null
              ? ClipOval(
                  child: Image.network(
                    provider.user!.profilePicUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultAvatar(),
                  ),
                )
              : _buildDefaultAvatar(),
        ),
        kGap20,
        // Name
        CustomText(
          text: _getDisplayName(provider.user),
          fontSize: isDesktop ? 28 : 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textColor,
          textAlign: TextAlign.center,
        ),
        kGap8,
        // Role Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary),
          ),
          child: CustomText(
            text: provider.userRole ?? 'USER',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        kGap20,
        // Email
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, size: 18, color: AppColors.hintColor),
            kGap8,
            CustomText(
              text: provider.userEmail ?? '',
              fontSize: 14,
              color: AppColors.hintColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileDetails(BuildContext context, bool isDesktop) {
    final provider = context.watch<ProfileProvider>();

    if (provider.isLoadingProfile) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            kGap16,
            CustomText(
              text: provider.error!,
              color: AppColors.error,
              textAlign: TextAlign.center,
            ),
            kGap20,
            CustomButton(
              text: 'Retry',
              onPressed: () => provider.loadProfile(),
              backgroundColor: AppColors.primary,
            ),
          ],
        ),
      );
    }

    if (provider.user == null) {
      return const Center(
        child: CustomText(
          text: 'No profile data available',
          color: AppColors.hintColor,
        ),
      );
    }

    final user = provider.user!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: 'Profile Information',
          fontSize: isDesktop ? 24 : 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textColor,
        ),
        kGap30,
        _buildInfoCard(
          context,
          'Personal Information',
          [
            _buildInfoRow('Username', user.username),
            _buildInfoRow('Phone', user.phone),
            _buildInfoRow('Gender', user.gender?.toUpperCase()),
            _buildInfoRow('Date of Birth', _formatDate(user.dob)),
            if (user.location != null)
              _buildInfoRow('Location', user.location!.formatted),
          ],
        ),
        kGap20,
        if (provider.userRole == 'DOCTOR' || provider.userRole == 'NURSE')
          _buildInfoCard(
            context,
            'Professional Information',
            [
              _buildInfoRow('Specialization', user.specialization),
              _buildInfoRow('Status', user.enabled ? 'ACTIVE' : 'INACTIVE'),
              if (user.medicalCertificateUrl != null)
                _buildInfoRow('Medical Certificate', 'Uploaded'),
              if (user.educationalCertificateUrl != null)
                _buildInfoRow('Educational Certificate', 'Uploaded'),
            ],
          ),
        kGap20,
        _buildInfoCard(
          context,
          'Account Information',
          [
            _buildInfoRow('Email', user.email),
            _buildInfoRow('Role', provider.userRole ?? user.primaryRole),
            _buildInfoRow('Status', user.enabled ? 'ACTIVE' : 'INACTIVE'),
            _buildInfoRow('Account Created', _formatDate(user.createdAt)),
            if (user.idDocumentUrl != null)
              _buildInfoRow('ID Document', 'Uploaded'),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: title,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
          kGap16,
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: CustomText(
              text: label,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.hintColor,
            ),
          ),
          Expanded(
            child: CustomText(
              text: value ?? 'N/A',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      size: 60,
      color: AppColors.primary,
    );
  }

  String _getDisplayName(User? user) {
    if (user == null) return 'User';
    
    if (user.username != null && user.username!.isNotEmpty) {
      return user.username!;
    }
    
    return user.email;
  }

  String? _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    
    try {
      // Handle ISO format: 2025-11-22T09:59:18.448455 or 2000-01-01
      final dateStr = dateString.split('T').first; // Get date part only
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        // Format: YYYY-MM-DD to DD-MM-YYYY
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  void _navigateToEditProfile(BuildContext context, ProfileProvider provider) {
    if (provider.user != null) {
      Get.to(() => ChangeNotifierProvider.value(
            value: provider, // Pass existing ProfileProvider
            child: ChangeNotifierProvider(
              create: (_) {
                final editProvider = EditProfileProvider();
                editProvider.initializeFromUser(
                  provider.user!,
                  provider.userRole ?? provider.user!.primaryRole,
                  provider.userEmail ?? provider.user!.email,
                );
                return editProvider;
              },
              child: const EditProfileView(),
            ),
          ));
    }
  }

  Future<void> _handleLogout(BuildContext context, ProfileProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const CustomText(
          text: 'Logout',
          fontWeight: FontWeight.w700,
        ),
        content: const CustomText(
          text: 'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const CustomText(
              text: 'Cancel',
              color: AppColors.hintColor,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const CustomText(
              text: 'Logout',
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.logout(context);
      if (context.mounted) {
        Get.offAll(() => LoginView());
      }
    }
  }
}

