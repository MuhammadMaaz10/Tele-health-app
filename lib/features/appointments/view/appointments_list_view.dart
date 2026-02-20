import 'package:flutter/foundation.dart';
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
    final isWeb = kIsWeb;
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? (screenWidth > 1600 ? 80 : screenWidth > 1200 ? 60 : 40) : (screenWidth > 1400 ? 60 : 40),
          vertical: isWeb ? 20 : 30,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWeb ? 1800 : 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section - Filters and Stats in one row
              _buildTopFiltersSection(context),
              SizedBox(height: isWeb ? 16 : 30),
              // Appointments List
              _buildAppointmentsList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopFiltersSection(BuildContext context) {
    final isWeb = kIsWeb;
    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        return _buildSegmentedControl(context, provider, isWeb);
      },
    );
  }

  Widget _buildSegmentedControl(BuildContext context, AppointmentProvider provider, bool isWeb) {
    final filterOptions = [
      {'label': 'All', 'status': null},
      {'label': 'Pending', 'status': AppointmentStatus.PENDING},
      {'label': 'Confirmed', 'status': AppointmentStatus.CONFIRMED},
      {'label': 'Rescheduled', 'status': AppointmentStatus.RESCHEDULED},
      {'label': 'Cancelled', 'status': AppointmentStatus.CANCELLED},
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isWeb ? 4 : 6, vertical: isWeb ? 4 : 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(isWeb ? 10 : 12),
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
          children: filterOptions.map((option) {
            final isSelected = provider.filterStatus == option['status'];
            return GestureDetector(
              onTap: () => provider.filterByStatus(option['status'] as AppointmentStatus?),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isWeb ? 16 : 20, vertical: isWeb ? 10 : 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      text: option['label'] as String,
                      fontSize: isWeb ? 14 : 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.textColor : AppColors.hintColor,
                    ),
                    SizedBox(height: isWeb ? 6 : 8),
                    Container(
                      width: isSelected ? (option['label'] as String).length * (isWeb ? 6.5 : 7.5) : 0,
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
        return _buildSegmentedControl(context, provider, false);
      },
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
        final isWeb = kIsWeb;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomText(
                  text: 'Appointments (${appointments.length})',
                  fontSize: isWeb && isDesktop ? 20 : (isDesktop ? 24 : 20),
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
            SizedBox(height: isWeb && isDesktop ? 12 : 20),
            // Web: Wrap grid with 2 items per row, Mobile/Tablet: List view
            if (isWeb && isDesktop)
              // Web desktop: Wrap layout with 2 items per row
              LayoutBuilder(
                builder: (context, constraints) {
                  final spacing = 16.0;
                  final itemWidth = (constraints.maxWidth - spacing) / 2;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: appointments.map((appointment) => SizedBox(
                      width: itemWidth,
                      child: _buildAppointmentCard(
                        context,
                        appointment,
                        provider,
                        isGridLayout: true,
                        isWeb: true,
                      ),
                    )).toList(),
                  );
                },
              )
            else
              // Mobile/Tablet: List view
              Column(
                children: appointments.map((appointment) => _buildAppointmentCard(
                      context,
                      appointment,
                      provider,
                      isGridLayout: false,
                      isWeb: false,
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
    AppointmentProvider provider, {
    bool isGridLayout = false,
    bool isWeb = false,
  }) {
    return Container(
      margin: isGridLayout ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isWeb ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isWeb ? 8 : 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToAppointmentDetails(context, appointment, provider),
          borderRadius: BorderRadius.circular(isWeb ? 12 : 16),
          child: Container(
            padding: EdgeInsets.all(isWeb && isGridLayout ? 12 : (isWeb ? 14 : 20)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isWeb ? 12 : 16),
              border: Border.all(
                color: _getStatusColor(appointment.status).withOpacity(0.3),
                width: isWeb ? 1 : 1.5,
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
                      width: isWeb && isGridLayout ? 50 : (isWeb ? 55 : 70),
                      padding: EdgeInsets.all(isWeb && isGridLayout ? 6 : (isWeb ? 8 : 12)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(isWeb ? 10 : 12),
                      ),
                      child: Column(
                        children: [
                          CustomText(
                            text: appointment.startTime.day.toString(),
                            fontSize: isWeb && isGridLayout ? 18 : (isWeb ? 20 : 24),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          CustomText(
                            text: _getMonthName(appointment.startTime.month),
                            fontSize: isWeb && isGridLayout ? 9 : (isWeb ? 10 : 11),
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isWeb && isGridLayout ? 10 : (isWeb ? 12 : 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  text: appointment.description,
                                  fontSize: isWeb && isGridLayout ? 13 : (isWeb ? 15 : 18),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textColor,
                                  maxLines: isWeb && isGridLayout ? 1 : (isWeb ? 1 : 2),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isWeb && isGridLayout)
                                IconButton(
                                  onPressed: () => _navigateToAppointmentDetails(
                                    context,
                                    appointment,
                                    provider,
                                  ),
                                  icon: Icon(Icons.visibility_outlined, size: 18),
                                  color: AppColors.primary,
                                  tooltip: 'Details',
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  style: IconButton.styleFrom(
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              SizedBox(width: isWeb && isGridLayout ? 4 : 8),
                              _buildStatusBadge(appointment.status, isWeb: isWeb),
                            ],
                          ),
                          SizedBox(height: isWeb && isGridLayout ? 6 : (isWeb ? 8 : 12)),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: isWeb ? 8 : 10, vertical: isWeb ? 4 : 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(isWeb ? 6 : 8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time, size: isWeb ? 12 : 14, color: AppColors.primary),
                                    SizedBox(width: isWeb ? 3 : 4),
                                    CustomText(
                                      text: appointment.formattedTime,
                                      fontSize: isWeb ? 11 : 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: isWeb ? 6 : 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: isWeb ? 8 : 10, vertical: isWeb ? 4 : 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(isWeb ? 6 : 8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer_outlined, size: isWeb ? 12 : 14, color: Colors.blue),
                                    SizedBox(width: isWeb ? 3 : 4),
                                    CustomText(
                                      text: '${appointment.duration.inMinutes} min',
                                      fontSize: isWeb ? 11 : 13,
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
                SizedBox(height: isWeb ? 8 : 12),
                Container(
                  padding: EdgeInsets.all(isWeb ? 8 : 12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(isWeb ? 8 : 10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isWeb ? 5 : 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(isWeb ? 6 : 8),
                        ),
                        child: Icon(
                          provider.userRole == 'PATIENT' ? Icons.local_hospital : Icons.person,
                          size: isWeb ? 14 : 18,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: isWeb ? 8 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: provider.userRole == 'PATIENT' ? 'Doctor' : 'Patient',
                              fontSize: isWeb ? 9 : 11,
                              color: AppColors.hintColor,
                            ),
                            SizedBox(height: 2),
                            CustomText(
                              text: provider.userRole == 'PATIENT'
                                  ? 'Dr. ${appointment.doctorAssigned.split('@').first}'
                                  : appointment.patientBooked,
                              fontSize: isWeb ? 11 : 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons - only show in list view, grid view has eye icon in header
                if (!isGridLayout) ...[
                  SizedBox(height: isWeb ? 8 : 12),
                  Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _navigateToAppointmentDetails(
                                context,
                                appointment,
                                provider,
                              ),
                              icon: Icon(Icons.visibility_outlined, size: isWeb ? 16 : 18),
                              label: CustomText(
                                text: 'Details',
                                fontSize: isWeb ? 12 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(color: AppColors.primary),
                                padding: EdgeInsets.symmetric(vertical: isWeb ? 10 : 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(isWeb ? 8 : 10),
                                ),
                              ),
                            ),
                          ),
                          if (appointment.status == AppointmentStatus.PENDING &&
                              provider.userRole == 'DOCTOR') ...[
                            SizedBox(width: isWeb ? 6 : 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handleConfirmAppointment(
                                  context,
                                  appointment.id,
                                  provider,
                                ),
                                icon: Icon(Icons.check_circle_outline, size: isWeb ? 16 : 18),
                                label: CustomText(
                                  text: 'Confirm',
                                  fontSize: isWeb ? 12 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: isWeb ? 10 : 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(isWeb ? 8 : 10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (appointment.status != AppointmentStatus.CANCELLED &&
                              appointment.isUpcoming) ...[
                            SizedBox(width: isWeb ? 6 : 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _handleCancelAppointment(
                                  context,
                                  appointment.id,
                                  provider,
                                ),
                                icon: Icon(Icons.cancel_outlined, size: isWeb ? 16 : 18),
                                label: CustomText(
                                  text: 'Cancel',
                                  fontSize: isWeb ? 12 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: BorderSide(color: AppColors.error),
                                  padding: EdgeInsets.symmetric(vertical: isWeb ? 10 : 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(isWeb ? 8 : 10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                ],
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

  Widget _buildStatusBadge(AppointmentStatus status, {bool isWeb = false}) {
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
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 10 : 12, vertical: isWeb ? 4 : 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isWeb ? 10 : 12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: CustomText(
        text: status.displayName,
        fontSize: isWeb ? 10 : 12,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  void _navigateToCreateAppointment(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    
    // On desktop, use Navigator.push to stay within sidebar
    // On mobile, use Get.to() for full screen navigation
    if (isDesktop) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (_) => CreateAppointmentProvider(),
            child: const CreateAppointmentView(),
          ),
        ),
      );
    } else {
      Get.to(() => ChangeNotifierProvider(
            create: (_) => CreateAppointmentProvider(),
            child: const CreateAppointmentView(),
          ));
    }
  }

  void _navigateToAppointmentDetails(
    BuildContext context,
    Appointment appointment,
    AppointmentProvider provider,
  ) {
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

