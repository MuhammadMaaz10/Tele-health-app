import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import '../controller/appointment_provider.dart';
import '../model/appointment_model.dart';
import 'update_appointment_view.dart';
import 'appointment_notes_view.dart';

// Expandable Description Widget for handling long text
class _ExpandableDescription extends StatefulWidget {
  final String label;
  final String description;

  const _ExpandableDescription({
    required this.label,
    required this.description,
  });

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _isExpanded = false;
  static const int _maxLinesCollapsed = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: CustomText(
                text: widget.label,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.hintColor,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: widget.description,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textColor,
                    maxLines: _isExpanded ? null : _maxLinesCollapsed,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                  ),
                  // Show expand/collapse button if text is potentially long
                  // We'll show it if description is longer than a threshold
                  if (widget.description.length > 100 || _isExpanded) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            text: _isExpanded ? 'Show less' : 'Show more',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AppointmentDetailsView extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailsView({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentDetailsView> createState() => _AppointmentDetailsViewState();
}

class _AppointmentDetailsViewState extends State<AppointmentDetailsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          text: 'Appointment Details',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textColor,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.hintColor,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Appointment Details'),
            Tab(text: 'Notes'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAppointmentDetailsTab(context, isDesktop, isTablet),
            _buildNotesTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentDetailsTab(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 40 : (isTablet ? 30 : 20)),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 800 : double.infinity,
            ),
            child: Consumer<AppointmentProvider>(
              builder: (context, provider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    _buildStatusBadge(widget.appointment.status),
                    kGap24,

                    // Single Combined Card with all appointment details
                    _buildCombinedDetailsCard(context, provider.userRole),

                    kGap24,

                    // Action Buttons (only show if there are actions available)
                    if (_hasActions(widget.appointment, provider.userRole))
                      _buildActions(context, provider),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesTab(BuildContext context) {
    return AppointmentNotesView(
      appointmentId: widget.appointment.id,
      isEmbeddedInTab: true,
    );
  }

  Widget _buildCombinedDetailsCard(BuildContext context, String? userRole) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          // Description with expandable functionality for long text
          _buildDescriptionRow(widget.appointment.description),
          kGap20,

          // Date
          _buildInfoRow('Date', widget.appointment.formattedDate),
          kGap20,

          // Time
          _buildInfoRow('Time', widget.appointment.formattedTime),
          kGap20,

          // Duration
          _buildInfoRow(
            'Duration',
            '${widget.appointment.duration.inMinutes} minutes',
          ),
          kGap20,

          // Status removed from card since it's shown as badge at top
          if (widget.appointment.rescheduled) ...[
            kGap20,
            _buildInfoRow('Rescheduled', 'Yes'),
          ],
          kGap20,

          // Divider
          const Divider(height: 1, color: AppColors.lightBorderColor),
          kGap20,

          // People Section
          CustomText(
            text: 'People',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
          kGap16,
          _buildInfoRow(
            userRole == 'PATIENT' ? 'Doctor' : 'Patient',
            userRole == 'PATIENT'
                ? widget.appointment.doctorAssigned
                : widget.appointment.patientBooked,
          ),
          kGap16,
          _buildInfoRow(
            userRole == 'PATIENT' ? 'Patient' : 'Doctor',
            userRole == 'PATIENT'
                ? widget.appointment.patientBooked
                : widget.appointment.doctorAssigned,
          ),
          kGap20,

          // Divider
          const Divider(height: 1, color: AppColors.lightBorderColor),
          kGap20,

          // Appointment Created Date
          CustomText(
            text: 'Appointment created date',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.hintColor,
          ),
          kGap8,
          CustomText(
            text: _formatCreatedDate(widget.appointment.createdAt),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textColor,
          ),
        ],
      ),
    );
  }

  bool _hasActions(Appointment appointment, String? userRole) {
    // Check if there are any actions available
    if (appointment.isUpcoming &&
        appointment.status != AppointmentStatus.CANCELLED) {
      return true; // Has reschedule/cancel
    }
    if (appointment.status == AppointmentStatus.PENDING &&
        userRole == 'DOCTOR') {
      return true; // Has confirm
    }
    return false;
  }

  Widget _buildActions(BuildContext context, AppointmentProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Reschedule Button (only for upcoming appointments)
        if (widget.appointment.isUpcoming &&
            widget.appointment.status != AppointmentStatus.CANCELLED)
          CustomButton(
            text: 'Reschedule',
            onPressed: () => _navigateToUpdate(context, provider),
            backgroundColor: AppColors.secondary,
          ),

        if (widget.appointment.isUpcoming &&
            widget.appointment.status != AppointmentStatus.CANCELLED) ...[
          kGap16,
        ],

        // Confirm Button (only for doctors and pending appointments)
        if (widget.appointment.status == AppointmentStatus.PENDING &&
            provider.userRole == 'DOCTOR')
          CustomButton(
            text: 'Confirm Appointment',
            onPressed: () => _handleConfirm(context, provider),
            backgroundColor: Colors.green,
          ),

        if (widget.appointment.status == AppointmentStatus.PENDING &&
            provider.userRole == 'DOCTOR') ...[
          kGap16,
        ],

        // Cancel Button (only for upcoming appointments)
        if (widget.appointment.isUpcoming &&
            widget.appointment.status != AppointmentStatus.CANCELLED)
          CustomButton(
            text: 'Cancel Appointment',
            onPressed: () => _handleCancel(context, provider),
            backgroundColor: AppColors.error,
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
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
            text: value,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionRow(String description) {
    return _ExpandableDescription(
      label: 'Description',
      description: description,
    );
  }

  Widget _buildStatusBadge(AppointmentStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case AppointmentStatus.PENDING:
        backgroundColor = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange.shade700;
        icon = Icons.pending_outlined;
        break;
      case AppointmentStatus.CONFIRMED:
        backgroundColor = Colors.green.withOpacity(0.15);
        textColor = Colors.green.shade700;
        icon = Icons.check_circle_outline;
        break;
      case AppointmentStatus.RESCHEDULED:
        backgroundColor = Colors.blue.withOpacity(0.15);
        textColor = Colors.blue.shade700;
        icon = Icons.schedule_outlined;
        break;
      case AppointmentStatus.CANCELLED:
        backgroundColor = Colors.red.withOpacity(0.15);
        textColor = Colors.red.shade700;
        icon = Icons.cancel_outlined;
        break;
      case AppointmentStatus.COMPLETED:
        backgroundColor = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey.shade700;
        icon = Icons.check_circle_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: textColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          CustomText(
            text: status.displayName,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ],
      ),
    );
  }

  String _formatCreatedDate(DateTime dateTime) {
    // Format: 23-nov-2025 at 5:25pm
    final months = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec'
    ];

    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;

    // Format time in 12-hour format
    int hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'pm' : 'am';
    
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour = hour - 12;
    }

    final minuteStr = minute.toString().padLeft(2, '0');

    return '$day-$month-$year at $hour:$minuteStr$period';
  }

  void _navigateToUpdate(BuildContext context, AppointmentProvider provider) {
    Get.to(() => UpdateAppointmentView(appointment: widget.appointment));
  }

  Future<void> _handleCancel(
    BuildContext context,
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
      final success = await provider.cancelAppointment(widget.appointment.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Appointment cancelled successfully'
                : provider.error ?? 'Failed to cancel appointment'),
            backgroundColor: success ? Colors.green : AppColors.error,
          ),
        );
        if (success) {
          Get.back();
        }
      }
    }
  }

  Future<void> _handleConfirm(
    BuildContext context,
    AppointmentProvider provider,
  ) async {
    final success = await provider.confirmAppointment(widget.appointment.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Appointment confirmed successfully'
              : provider.error ?? 'Failed to confirm appointment'),
          backgroundColor: success ? Colors.green : AppColors.error,
        ),
      );
      if (success) {
        Get.back();
      }
    }
  }
}
