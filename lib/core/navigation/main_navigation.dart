import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/features/appointments/view/appointments_list_view.dart';
import 'package:telehealth_app/features/profile/view/profile_view.dart';
import 'package:telehealth_app/features/dashboard/view/dashboard_view.dart';
import 'package:telehealth_app/features/profile/controller/profile_provider.dart';
import 'package:telehealth_app/features/auth/login/view/login_view.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/core/navigation/navigation_controller.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final NavigationController _navigationController = NavigationController();
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardView(),
    const AppointmentsListView(),
    const ProfileView(),
  ];

  // Navigator keys for each screen to maintain separate navigation stacks
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    // Listen to navigation controller changes
    _navigationController.addListener(_onNavigationChanged);
    // Trigger data loading after navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _onNavigationChanged() {
    if (_currentIndex != _navigationController.currentIndex) {
      // Pop all routes from the current navigator before switching
      final currentNavigator = _navigatorKeys[_currentIndex].currentState;
      if (currentNavigator != null && currentNavigator.canPop()) {
        currentNavigator.popUntil((route) => route.isFirst);
      }
      setState(() {
        _currentIndex = _navigationController.currentIndex;
      });
    }
  }

  @override
  void dispose() {
    _navigationController.removeListener(_onNavigationChanged);
    super.dispose();
  }

  void _loadInitialData() {
    // This will be handled by the providers' initialization
    // But we can force a refresh if needed
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    
    return ChangeNotifierProvider.value(
      value: _navigationController,
      child: _buildNavigationContent(isDesktop),
    );
  }

  Widget _buildNavigationContent(bool isDesktop) {

    // On desktop, show side navigation instead of bottom nav
    if (isDesktop) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          children: [
            // Side Navigation
            Container(
              width: 280,
              color: Colors.white,
              child: Column(
                children: [
                  // Header Section
                  _buildSidebarHeader(),
                  
                  // Navigation Items
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                  _buildNavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Dashboard',
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today,
                    label: 'Appointments',
                    index: 1,
                  ),
                  _buildNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    index: 2,
                  ),
                ],
              ),
                    ),
                  ),
                  
                  // Footer Section with User Info
                  _buildSidebarFooter(context),
                ],
              ),
            ),
            // Divider
            Container(
              width: 1,
              color: AppColors.lightBorderColor,
            ),
            // Main Content with nested Navigator for sidebar navigation
            Expanded(
              child: Container(
                color: Colors.white,
                child: Navigator(
                  key: _navigatorKeys[_currentIndex],
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) => _screens[_currentIndex],
                      settings: settings,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile/Tablet: Bottom Navigation Bar
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            _navigationController.switchToTab(index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.hintColor,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.lightBorderColor.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medical_services,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'Telehealth',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColor,
                ),
                CustomText(
                  text: 'Services',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.hintColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
      onTap: () {
        _navigationController.switchToTab(index);
      },
          borderRadius: BorderRadius.circular(12),
      child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary.withOpacity(0.1) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
                  color: isSelected ? AppColors.primary : AppColors.hintColor,
                  size: 22,
            ),
                const SizedBox(width: 14),
            CustomText(
              text: label,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textColor,
            ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final userEmail = profileProvider.userEmail ?? '';
        final userName = profileProvider.user?.username ?? 
                        userEmail.split('@').first;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            border: Border(
              top: BorderSide(
                color: AppColors.lightBorderColor.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // User Info
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CustomText(
                        text: userName.isNotEmpty 
                            ? userName[0].toUpperCase() 
                            : 'U',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: userName,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColor,
                        ),
                        if (userEmail.isNotEmpty)
                          CustomText(
                            text: userEmail,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.hintColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Logout Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleLogout(context, profileProvider),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.logout,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const CustomText(
                          text: 'Logout',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context, ProfileProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const CustomText(
          text: 'Logout',
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        content: const CustomText(
          text: 'Are you sure you want to logout?',
          fontSize: 14,
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
              color: Colors.red,
              fontWeight: FontWeight.w600,
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



