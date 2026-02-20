import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/features/auth/login/view/login_view.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:telehealth_app/shared_widgets/shimmer_widget.dart';
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

class _ProfileViewBody extends StatefulWidget {
  const _ProfileViewBody({Key? key}) : super(key: key);

  @override
  State<_ProfileViewBody> createState() => _ProfileViewBodyState();
}

class _ProfileViewBodyState extends State<_ProfileViewBody> {
  int _selectedTabIndex = 0; // 0 for Personal, 1 for Professional, 2 for Account

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
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(context, isDesktop),
            // Segmented Control Tabs
            Padding(
              padding: EdgeInsets.only(
                left: isDesktop ? 40 : (isTablet ? 30 : 20),
                right: isDesktop ? 40 : (isTablet ? 30 : 20),
                top: 16,
                bottom: 16,
              ),
              child: _buildSegmentedControl(isDesktop),
            ),
            // Content based on selected tab
            Expanded(
              child: isDesktop
                  ? _buildDesktopLayout(context)
                  : _buildMobileTabletLayout(context, isTablet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl(bool isDesktop) {
    final provider = context.watch<ProfileProvider>();
    final isDoctorOrNurse = provider.userRole == 'DOCTOR' || provider.userRole == 'NURSE';
    
    final tabs = isDoctorOrNurse
        ? [
            {'label': 'Personal', 'index': 0},
            {'label': 'Professional', 'index': 1},
            {'label': 'Account', 'index': 2},
          ]
        : [
            {'label': 'Personal', 'index': 0},
            {'label': 'Account', 'index': 1},
          ];

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 4 : 6, vertical: isDesktop ? 4 : 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(isDesktop ? 10 : 12),
          border: Border.all(
            color: AppColors.lightBorderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: tabs.map((tab) {
            final isSelected = _selectedTabIndex == tab['index'] as int;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = tab['index'] as int;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 16 : 20,
                  vertical: isDesktop ? 10 : 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      text: tab['label'] as String,
                      fontSize: isDesktop ? 14 : 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.textColor : AppColors.hintColor,
                    ),
                    SizedBox(height: isDesktop ? 6 : 8),
                    Container(
                      width: isSelected
                          ? (tab['label'] as String).length * (isDesktop ? 6.5 : 7.5)
                          : 0,
                      height: 2,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, bool isDesktop) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingProfile) {
          return Padding(
            padding: EdgeInsets.all(isDesktop ? 40 : 20),
            child: Skeletonizer(
              enabled: true,
              child: Row(
                children: [
                  Container(
                    width: isDesktop ? 80 : 60,
                    height: isDesktop ? 80 : 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 24, width: 150, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 16, width: 200, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(isDesktop ? 40 : 20),
          child: Row(
            children: [
              // Profile Picture
              Container(
                width: isDesktop ? 80 : 60,
                height: isDesktop ? 80 : 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: provider.user?.profilePicUrl != null
                      ? ClipOval(
                          child: Image.network(
                            provider.user!.profilePicUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultAvatar(isDesktop),
                          ),
                        )
                      : _buildDefaultAvatar(isDesktop),
                ),
              ),
              const SizedBox(width: 20),
              // Name and Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: _getDisplayName(provider.user),
                      fontSize: isDesktop ? 28 : 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textColor,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          CustomText(
                            text: provider.userRole ?? 'USER',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultAvatar([bool isDesktop = false]) {
    return Icon(
      Icons.person,
      size: isDesktop ? 40 : 30,
      color: AppColors.primary,
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 40,
          right: 40,
          top: 0,
          bottom: 20,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildTabContent(context, true),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTabletLayout(BuildContext context, bool isTablet) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: isTablet ? 30 : 20,
          right: isTablet ? 30 : 20,
          top: 0,
          bottom: isTablet ? 30 : 20,
        ),
        child: _buildTabContent(context, false),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, bool isDesktop) {
    final provider = context.watch<ProfileProvider>();
    final isDoctorOrNurse = provider.userRole == 'DOCTOR' || provider.userRole == 'NURSE';

    if (provider.isLoadingProfile) {
      return Column(
        children: List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: ShimmerCard(height: 120),
        )),
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

    if (isDoctorOrNurse) {
      switch (_selectedTabIndex) {
        case 0:
          return _buildPersonalInfoTab(context, user, provider, isDesktop);
        case 1:
          return _buildProfessionalInfoTab(context, user, provider, isDesktop);
        case 2:
          return _buildAccountInfoTab(context, user, provider, isDesktop);
        default:
          return _buildPersonalInfoTab(context, user, provider, isDesktop);
      }
    } else {
      switch (_selectedTabIndex) {
        case 0:
          return _buildPersonalInfoTab(context, user, provider, isDesktop);
        case 1:
          return _buildAccountInfoTab(context, user, provider, isDesktop);
        default:
          return _buildPersonalInfoTab(context, user, provider, isDesktop);
      }
    }
  }

  Widget _buildPersonalInfoTab(BuildContext context, User user, ProfileProvider provider, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          context,
          Icons.person_outline,
          'Personal Information',
          [
            _buildInfoRow('Username', user.username),
            _buildInfoRow('Phone', user.phone),
            _buildInfoRow('Gender', user.gender?.toUpperCase()),
            _buildInfoRow('Date of Birth', _formatDate(user.dob)),
            if (user.location != null)
              _buildInfoRow('Location', user.location!.readableAddress),
          ],
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoTab(BuildContext context, User user, ProfileProvider provider, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          context,
          Icons.medical_services_outlined,
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
      ],
    );
  }

  Widget _buildAccountInfoTab(BuildContext context, User user, ProfileProvider provider, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          context,
          Icons.account_circle_outlined,
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
    IconData icon,
    String title,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              CustomText(
                text: title,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textColor,
              ),
            ],
          ),
          kGap20,
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

