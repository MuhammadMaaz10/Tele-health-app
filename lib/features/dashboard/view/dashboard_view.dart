import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/shimmer_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:telehealth_app/features/appointments/controller/appointment_provider.dart';
import 'package:telehealth_app/features/profile/controller/profile_provider.dart';
import 'package:telehealth_app/features/appointments/model/appointment_model.dart';
import 'package:telehealth_app/features/appointments/controller/create_appointment_provider.dart';
import 'package:telehealth_app/features/appointments/view/create_appointment_view.dart';
import 'package:telehealth_app/features/appointments/view/appointment_details_view.dart';
import 'package:telehealth_app/core/navigation/navigation_controller.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isDesktop
          ? _buildDesktopLayout(context)
          : _buildMobileLayout(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        // AppBar aligned with sidebar header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Row(
            children: [
              Expanded(
                child: Consumer<ProfileProvider>(
                  builder: (context, profileProvider, child) {
                    if (profileProvider.isLoadingProfile) {
                      return Row(
                        children: [
                          Container(height: 32, width: 150, color: AppColors.hintColor.withOpacity(0.3)),
                        ],
                      );
                    }

                    final user = profileProvider.user;
                    final userName = user?.username ?? 
                                    (user?.email != null ? user!.email.split('@').first : null) ?? 
                                    (profileProvider.userEmail != null && profileProvider.userEmail!.isNotEmpty 
                                      ? profileProvider.userEmail!.split('@').first 
                                      : null) ??
                                    'User';
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          text: 'Hi, $userName',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textColor,
                        ),
                        CustomText(
                          text: "Let's finish your task today!",
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.hintColor,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Consumer<ProfileProvider>(
                builder: (context, provider, child) {
                  return IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                    onPressed: () {},
                    tooltip: 'Notifications',
                  );
                },
              ),
            ],
          ),
        ),
        // Scrollable content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
              final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
              await Future.wait([
                appointmentProvider.loadAppointments(),
                profileProvider.loadProfile(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCards(context),
                  kGap30,
                  _buildUpcomingAppointments(context),
                  kGap30,
                  _buildQuickActions(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            if (profileProvider.isLoadingProfile) {
              return Row(
                children: [
                  Container(height: 32, width: 150, color: AppColors.hintColor.withOpacity(0.3)),
                ],
              );
            }

            final user = profileProvider.user;
            final userName = user?.username ?? 
                            (user?.email != null ? user!.email.split('@').first : null) ?? 
                            (profileProvider.userEmail != null && profileProvider.userEmail!.isNotEmpty 
                              ? profileProvider.userEmail!.split('@').first 
                              : null) ??
                            'User';
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: 'Hi, $userName',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColor,
                ),
                CustomText(
                  text: "Let's finish your task today!",
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.hintColor,
                ),
              ],
            );
          },
        ),
        actions: [
          Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                onPressed: () {},
                tooltip: 'Notifications',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
            final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
            await Future.wait([
              appointmentProvider.loadAppointments(),
              profileProvider.loadProfile(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isTablet ? 30 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCards(context),
                kGap30,
                _buildUpcomingAppointments(context),
                kGap30,
                _buildQuickActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, appointmentProvider, child) {
        if (appointmentProvider.isLoadingAppointments) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText(
                text: 'Statistics',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textColor,
              ),
              kGap12,
              Row(
                children: [
                  const Expanded(child: ShimmerStatCard()),
                  const SizedBox(width: 8),
                  const Expanded(child: ShimmerStatCard()),
                  const SizedBox(width: 8),
                  const Expanded(child: ShimmerStatCard()),
                  const SizedBox(width: 8),
                  const Expanded(child: ShimmerStatCard()),
                ],
              ),
            ],
          );
        }

        final cancelled = appointmentProvider.getAppointmentsByStatus(AppointmentStatus.CANCELLED).length;
        final total = appointmentProvider.appointments.length;
        final completed = appointmentProvider.getAppointmentsByStatus(AppointmentStatus.COMPLETED).length;
        final confirmed = appointmentProvider.getAppointmentsByStatus(AppointmentStatus.CONFIRMED).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomText(
              text: 'Statistics',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textColor,
            ),
            kGap12,
            // Horizontal Row for all stats cards
            Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isMobile = screenWidth < 768;
                final isDesktop = screenWidth > 1024;
                final cardSpacing = isMobile ? 6.0 : 8.0;
                
                // For desktop, constrain the width and center the cards
                if (isDesktop) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              icon: FontAwesomeIcons.calendarCheck,
                              title: 'Total',
                              value: total.toString(),
                              color: AppColors.primary,
                              onTap: () => _navigateToAppointmentsWithFilter(context, null),
                            ),
                          ),
                          SizedBox(width: cardSpacing),
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              icon: FontAwesomeIcons.circleCheck,
                              title: 'Confirmed',
                              value: confirmed.toString(),
                              color: Colors.green,
                              onTap: () => _navigateToAppointmentsWithFilter(
                                context,
                                AppointmentStatus.CONFIRMED,
                              ),
                            ),
                          ),
                          SizedBox(width: cardSpacing),
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              icon: FontAwesomeIcons.clipboardCheck,
                              title: 'Completed',
                              value: completed.toString(),
                              color: Colors.green,
                              onTap: () => _navigateToAppointmentsWithFilter(
                                context,
                                AppointmentStatus.COMPLETED,
                              ),
                            ),
                          ),
                          SizedBox(width: cardSpacing),
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              icon: FontAwesomeIcons.calendarXmark,
                              title: 'Cancelled',
                              value: cancelled.toString(),
                              color: Colors.red,
                              onTap: () => _navigateToAppointmentsWithFilter(
                                context,
                                AppointmentStatus.CANCELLED,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // For mobile, show 2 cards per row
                if (isMobile) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate width: (available width - spacing between cards) / 2
                      final cardWidth = (constraints.maxWidth - cardSpacing) / 2;
                      return Wrap(
                        spacing: cardSpacing,
                        runSpacing: cardSpacing,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              context: context,
                              icon: FontAwesomeIcons.calendarCheck,
                              title: 'Total',
                              value: total.toString(),
                              color: AppColors.primary,
                              onTap: () => _navigateToAppointmentsWithFilter(context, null),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              context: context,
                              icon: FontAwesomeIcons.circleCheck,
                              title: 'Confirmed',
                              value: confirmed.toString(),
                              color: Colors.green,
                              onTap: () => _navigateToAppointmentsWithFilter(
                                context,
                                AppointmentStatus.CONFIRMED,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              context: context,
                              icon: FontAwesomeIcons.clipboardCheck,
                              title: 'Completed',
                              value: completed.toString(),
                              color: Colors.green,
                              onTap: () => _navigateToAppointmentsWithFilter(
                                context,
                                AppointmentStatus.COMPLETED,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              context: context,
                              icon: FontAwesomeIcons.calendarXmark,
                              title: 'Cancelled',
                              value: cancelled.toString(),
                              color: Colors.red,
                              onTap: () => _navigateToAppointmentsWithFilter(
                                context,
                                AppointmentStatus.CANCELLED,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
                
                // For tablet, use full width row
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: FontAwesomeIcons.calendarCheck,
                        title: 'Total',
                        value: total.toString(),
                        color: AppColors.primary,
                        onTap: () => _navigateToAppointmentsWithFilter(context, null),
                      ),
                    ),
                    SizedBox(width: cardSpacing),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: FontAwesomeIcons.circleCheck,
                        title: 'Confirmed',
                        value: confirmed.toString(),
                        color: Colors.green,
                        onTap: () => _navigateToAppointmentsWithFilter(
                          context,
                          AppointmentStatus.CONFIRMED,
                        ),
                      ),
                    ),
                    SizedBox(width: cardSpacing),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: FontAwesomeIcons.clipboardCheck,
                        title: 'Completed',
                        value: completed.toString(),
                        color: Colors.green,
                        onTap: () => _navigateToAppointmentsWithFilter(
                          context,
                          AppointmentStatus.COMPLETED,
                        ),
                      ),
                    ),
                    SizedBox(width: cardSpacing),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: FontAwesomeIcons.calendarXmark,
                        title: 'Cancelled',
                        value: cancelled.toString(),
                        color: Colors.red,
                        onTap: () => _navigateToAppointmentsWithFilter(
                          context,
                          AppointmentStatus.CANCELLED,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 14 : 16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading Icon
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                ),
                child: Icon(icon, color: color, size: isMobile ? 18 : 22),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              // Title and Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Label (Title) - smaller, grey text on top
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Value - large, bold text below
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
  }

  Widget _buildUpcomingAppointments(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, appointmentProvider, child) {
        final upcoming = appointmentProvider.upcomingAppointments.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CustomText(
                  text: 'Upcoming Appointments',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColor,
                ),
                TextButton(
                  onPressed: () {
                    _navigateToAppointmentsList(context);
                  },
                  child: const CustomText(
                    text: 'View All',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            kGap16,
            if (appointmentProvider.isLoadingAppointments)
              Column(
                children: List.generate(3, (index) => const ShimmerAppointmentCard()),
              )
            else if (upcoming.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightBorderColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.hintColor),
                    kGap12,
                    CustomText(
                      text: 'No upcoming appointments',
                      fontSize: 14,
                      color: AppColors.hintColor,
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: upcoming.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < upcoming.length - 1 ? 12 : 0,
                      ),
                      child: _buildAppointmentCard(context, upcoming[index]),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment appointment) {
    return Consumer<AppointmentProvider>(
      builder: (context, appointmentProvider, child) {
        final userRole = appointmentProvider.userRole;
        final isPatient = userRole == 'PATIENT';
        
        // For patients: show doctor info, For doctors/nurses: show patient info
        final personName = isPatient
            ? appointment.doctorDisplayName
            : appointment.patientDisplayName;
        final personEmail = isPatient
            ? appointment.doctorAssigned
            : appointment.patientBooked;
        final personLabel = isPatient ? 'Doctor' : 'Patient';
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToAppointmentDetails(context, appointment),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Person Name at the top (Doctor for patients, Patient for doctors)
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: AppColors.hintColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: CustomText(
                          text: isPatient ? 'Dr. $personName' : 'Patient: $personName',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusChip(appointment.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Date, Time section
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomText(
                              text: appointment.startTime.day.toString(),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                            CustomText(
                              text: _getMonthName(appointment.startTime.month),
                              fontSize: 9,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 12, color: AppColors.hintColor),
                                const SizedBox(width: 4),
                                CustomText(
                                  text: appointment.formattedTime,
                                  fontSize: 12,
                                  color: AppColors.hintColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            CustomText(
                              text: personLabel,
                              fontSize: 10,
                              color: AppColors.hintColor,
                            ),
                            const SizedBox(height: 2),
                            CustomText(
                              text: personEmail,
                              fontSize: 11,
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
                  // Description at the bottom
                  CustomText(
                    text: appointment.description,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToAppointmentDetails(BuildContext context, Appointment appointment) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    
    // On desktop, use Navigator.push to stay within sidebar
    // On mobile, use Get.to() for full screen navigation
    if (isDesktop) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppointmentDetailsView(appointment: appointment),
        ),
      );
    } else {
      Get.to(() => AppointmentDetailsView(appointment: appointment));
    }
  }

  void _navigateToAppointmentsList(BuildContext context) {
    // Switch to appointments tab using navigation controller
    final navigationController = Provider.of<NavigationController>(context, listen: false);
    navigationController.switchToAppointments();
  }

  void _navigateToAppointmentsWithFilter(
    BuildContext context,
    AppointmentStatus? status,
  ) {
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    appointmentProvider.filterByStatus(status);
    _navigateToAppointmentsList(context);
  }

  Widget _buildStatusChip(AppointmentStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case AppointmentStatus.PENDING:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case AppointmentStatus.CONFIRMED:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case AppointmentStatus.RESCHEDULED:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        break;
      case AppointmentStatus.CANCELLED:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomText(
        text: status.displayName,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CustomText(
          text: 'Quick Actions',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textColor,
        ),
        kGap16,
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle_outline,
                title: 'New Appointment',
                color: AppColors.primary,
                onTap: () {
                  Get.to(() => ChangeNotifierProvider(
                    create: (_) => CreateAppointmentProvider(),
                    child: const CreateAppointmentView(),
                  ));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.calendar_view_week,
                title: 'View All',
                color: Colors.blue,
                onTap: () {
                  _navigateToAppointmentsList(context);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            kGap12,
            CustomText(
              text: title,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

