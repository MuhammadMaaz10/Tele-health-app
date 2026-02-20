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
import 'package:get/get.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

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
            padding: EdgeInsets.all(isDesktop ? 40 : isTablet ? 30 : 20),
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

        final upcoming = appointmentProvider.upcomingAppointments.length;
        final total = appointmentProvider.appointments.length;
        final pending = appointmentProvider.getAppointmentsByStatus(AppointmentStatus.PENDING).length;
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
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.calendar_today,
                    title: 'Total',
                    value: total.toString(),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.upcoming,
                    title: 'Upcoming',
                    value: upcoming.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.pending,
                    title: 'Pending',
                    value: pending.toString(),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    title: 'Confirmed',
                    value: confirmed.toString(),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          CustomText(
            text: value,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textColor,
          ),
          const SizedBox(height: 2),
          CustomText(
            text: title,
            fontSize: 11,
            color: AppColors.hintColor,
          ),
        ],
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
                    // Navigate to appointments tab
                    // This will be handled by parent navigation
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
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightBorderColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.hintColor),
                    kGap16,
                    CustomText(
                      text: 'No upcoming appointments',
                      fontSize: 16,
                      color: AppColors.hintColor,
                    ),
                  ],
                ),
              )
            else
              ...upcoming.map((appointment) => _buildAppointmentCard(appointment)),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: appointment.startTime.day.toString(),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                CustomText(
                  text: _getMonthName(appointment.startTime.month),
                  fontSize: 10,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: appointment.description,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
                kGap4,
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: AppColors.hintColor),
                    const SizedBox(width: 4),
                    CustomText(
                      text: appointment.formattedTime,
                      fontSize: 14,
                      color: AppColors.hintColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildStatusChip(appointment.status),
        ],
      ),
    );
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
                  // Navigate to appointments tab
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

