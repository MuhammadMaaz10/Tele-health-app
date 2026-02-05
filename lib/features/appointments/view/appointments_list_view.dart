import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import '../controller/appointment_provider.dart';
import '../controller/create_appointment_provider.dart';
import '../model/appointment_model.dart';
import 'appointment_details_view.dart';
import 'create_appointment_view.dart';

class AppointmentsListView extends StatelessWidget {
  const AppointmentsListView({super.key});

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
        title: const CustomText(
          text: 'My Appointments',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textColor,
        ),
        actions: [
          Consumer<AppointmentProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                onPressed: provider.isLoadingAppointments
                    ? null
                    : () => provider.loadAppointments(),
                tooltip: 'Refresh',
              );
            },
          ),
          Consumer<AppointmentProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.add, color: AppColors.primary),
                onPressed: () => _navigateToCreateAppointment(context),
                tooltip: 'New Appointment',
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
    final screenWidth = MediaQuery.of(context).size.width;
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth > 1400 ? 60 : 40,
          vertical: 30,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section - Filters and Stats in one row
              _buildTopFiltersSection(context),
              kGap30,
              // Appointments List
              _buildAppointmentsList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopFiltersSection(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(24),
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
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_list, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const CustomText(
                    text: 'Filter by Status',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ],
              ),
              kGap16,
              // Filter chips - Wrap layout
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildFilterChip(
                    context,
                    Icons.all_inclusive,
                    'All',
                    provider.filterStatus == null,
                    () => provider.filterByStatus(null),
                    AppColors.primary,
                  ),
                  _buildFilterChip(
                    context,
                    Icons.pending_outlined,
                    'Pending',
                    provider.filterStatus == AppointmentStatus.PENDING,
                    () => provider.filterByStatus(AppointmentStatus.PENDING),
                    Colors.orange,
                  ),
                  _buildFilterChip(
                    context,
                    Icons.check_circle_outline,
                    'Confirmed',
                    provider.filterStatus == AppointmentStatus.CONFIRMED,
                    () => provider.filterByStatus(AppointmentStatus.CONFIRMED),
                    Colors.green,
                  ),
                  _buildFilterChip(
                    context,
                    Icons.update,
                    'Rescheduled',
                    provider.filterStatus == AppointmentStatus.RESCHEDULED,
                    () => provider.filterByStatus(AppointmentStatus.RESCHEDULED),
                    Colors.blue,
                  ),
                  _buildFilterChip(
                    context,
                    Icons.cancel_outlined,
                    'Cancelled',
                    provider.filterStatus == AppointmentStatus.CANCELLED,
                    () => provider.filterByStatus(AppointmentStatus.CANCELLED),
                    Colors.red,
                  ),
                ],
              ),
              kGap20,
              const Divider(height: 1),
              kGap20,
              // Quick Stats - Horizontal Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      Icons.pending_outlined,
                      'Pending',
                      provider.getAppointmentsByStatus(AppointmentStatus.PENDING).length,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      Icons.check_circle_outline,
                      'Confirmed',
                      provider.getAppointmentsByStatus(AppointmentStatus.CONFIRMED).length,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      Icons.calendar_today,
                      'Total',
                      provider.appointments.length,
                      AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileTabletLayout(BuildContext context, bool isTablet) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 40 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(context),
            kGap30,
            _buildAppointmentsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const CustomText(
                  text: 'Filter by Status',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
              ],
            ),
            kGap12,
            // Mobile/Tablet: Horizontal scroll
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip(
                    context,
                    Icons.all_inclusive,
                    'All',
                    provider.filterStatus == null,
                    () => provider.filterByStatus(null),
                    AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    Icons.pending_outlined,
                    'Pending',
                    provider.filterStatus == AppointmentStatus.PENDING,
                    () => provider.filterByStatus(AppointmentStatus.PENDING),
                    Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    Icons.check_circle_outline,
                    'Confirmed',
                    provider.filterStatus == AppointmentStatus.CONFIRMED,
                    () => provider.filterByStatus(AppointmentStatus.CONFIRMED),
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    Icons.update,
                    'Rescheduled',
                    provider.filterStatus == AppointmentStatus.RESCHEDULED,
                    () => provider.filterByStatus(AppointmentStatus.RESCHEDULED),
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    Icons.cancel_outlined,
                    'Cancelled',
                    provider.filterStatus == AppointmentStatus.CANCELLED,
                    () => provider.filterByStatus(AppointmentStatus.CANCELLED),
                    Colors.red,
                  ),
                ],
              ),
            ),
            kGap16,
            // Quick Stats - Horizontal Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    Icons.pending_outlined,
                    'Pending',
                    provider.getAppointmentsByStatus(AppointmentStatus.PENDING).length,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    Icons.check_circle_outline,
                    'Confirmed',
                    provider.getAppointmentsByStatus(AppointmentStatus.CONFIRMED).length,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    Icons.calendar_today,
                    'Total',
                    provider.appointments.length,
                    AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : AppColors.lightBorderColor,
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            CustomText(
              text: label,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: count.toString(),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColor,
                ),
                CustomText(
                  text: label,
                  fontSize: 10,
                  color: AppColors.hintColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingAppointments) {
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
                  onPressed: () => provider.loadAppointments(),
                  backgroundColor: AppColors.primary,
                ),
              ],
            ),
          );
        }

        final appointments = provider.filteredAppointments;

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 64, color: AppColors.hintColor),
                kGap16,
                CustomText(
                  text: 'No appointments found',
                  fontSize: 18,
                  color: AppColors.hintColor,
                ),
                kGap8,
                CustomText(
                  text: 'Tap the + button to create a new appointment',
                  fontSize: 14,
                  color: AppColors.hintColor,
                ),
              ],
            ),
          );
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth > 1024;
        final isLargeDesktop = screenWidth > 1400;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomText(
                  text: 'Appointments (${appointments.length})',
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColor,
                ),
                if (isDesktop)
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreateAppointment(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const CustomText(
                      text: 'New Appointment',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
              ],
            ),
            kGap20,
            // Responsive grid for large desktop, list for regular desktop/mobile
            if (isLargeDesktop)
              // Large desktop: 2 columns grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.1,
                ),
                itemCount: appointments.length,
                itemBuilder: (context, index) => _buildAppointmentCard(
                  context,
                  appointments[index],
                  provider,
                ),
              )
            else
              // Regular desktop/mobile: List view
              Column(
                children: appointments.map((appointment) => _buildAppointmentCard(
                      context,
                      appointment,
                      provider,
                    )).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    Appointment appointment,
    AppointmentProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToAppointmentDetails(context, appointment, provider),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getStatusColor(appointment.status).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date/Time Badge
                    Container(
                      width: 70,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          CustomText(
                            text: appointment.startTime.day.toString(),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          CustomText(
                            text: _getMonthName(appointment.startTime.month),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  text: appointment.description,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textColor,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildStatusBadge(appointment.status),
                            ],
                          ),
                          kGap12,
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    CustomText(
                                      text: appointment.formattedTime,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer_outlined, size: 14, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    CustomText(
                                      text: '${appointment.duration.inMinutes} min',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                kGap16,
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          provider.userRole == 'PATIENT' ? Icons.local_hospital : Icons.person,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: provider.userRole == 'PATIENT' ? 'Doctor' : 'Patient',
                              fontSize: 11,
                              color: AppColors.hintColor,
                            ),
                            kGap2,
                            CustomText(
                              text: provider.userRole == 'PATIENT'
                                  ? 'Dr. ${appointment.doctorAssigned.split('@').first}'
                                  : appointment.patientBooked,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                kGap16,
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToAppointmentDetails(
                          context,
                          appointment,
                          provider,
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const CustomText(
                          text: 'Details',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    if (appointment.status == AppointmentStatus.PENDING &&
                        provider.userRole == 'DOCTOR') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleConfirmAppointment(
                            context,
                            appointment.id,
                            provider,
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const CustomText(
                            text: 'Confirm',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (appointment.status != AppointmentStatus.CANCELLED &&
                        appointment.isUpcoming) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleCancelAppointment(
                            context,
                            appointment.id,
                            provider,
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const CustomText(
                            text: 'Cancel',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.PENDING:
        return Colors.orange;
      case AppointmentStatus.CONFIRMED:
        return Colors.green;
      case AppointmentStatus.RESCHEDULED:
        return Colors.blue;
      case AppointmentStatus.CANCELLED:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildStatusBadge(AppointmentStatus status) {
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
      case AppointmentStatus.COMPLETED:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: CustomText(
        text: status.displayName,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  void _navigateToCreateAppointment(BuildContext context) {
    Get.to(() => ChangeNotifierProvider(
          create: (_) => CreateAppointmentProvider(),
          child: const CreateAppointmentView(),
        ));
  }

  void _navigateToAppointmentDetails(
    BuildContext context,
    Appointment appointment,
    AppointmentProvider provider,
  ) {
    Get.to(() => AppointmentDetailsView(appointment: appointment));
  }

  Future<void> _handleCancelAppointment(
    BuildContext context,
    int appointmentId,
    AppointmentProvider provider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const CustomText(
          text: 'Cancel Appointment',
          fontWeight: FontWeight.w700,
        ),
        content: const CustomText(
          text: 'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const CustomText(
              text: 'No',
              color: AppColors.hintColor,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const CustomText(
              text: 'Yes, Cancel',
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.cancelAppointment(appointmentId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Appointment cancelled successfully'
                : provider.error ?? 'Failed to cancel appointment'),
            backgroundColor: success ? Colors.green : AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleConfirmAppointment(
    BuildContext context,
    int appointmentId,
    AppointmentProvider provider,
  ) async {
    final success = await provider.confirmAppointment(appointmentId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Appointment confirmed successfully'
              : provider.error ?? 'Failed to confirm appointment'),
          backgroundColor: success ? Colors.green : AppColors.error,
        ),
      );
    }
  }
}

