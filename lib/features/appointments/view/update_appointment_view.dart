import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/text_field.dart';
import 'package:telehealth_app/shared_widgets/responsive_auth_layout.dart';
import '../controller/appointment_provider.dart';
import '../model/appointment_model.dart';

class UpdateAppointmentView extends StatefulWidget {
  final Appointment appointment;

  const UpdateAppointmentView({
    super.key,
    required this.appointment,
  });

  @override
  State<UpdateAppointmentView> createState() => _UpdateAppointmentViewState();
}

class _UpdateAppointmentViewState extends State<UpdateAppointmentView> {
  late TextEditingController dateController;
  late TextEditingController timeController;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    dateController = TextEditingController();
    timeController = TextEditingController();
    selectedDate = widget.appointment.startTime;
    selectedTime = TimeOfDay.fromDateTime(widget.appointment.startTime);
    dateController.text = _formatDateForInput(widget.appointment.startTime);
    timeController.text = _formatTimeForInput(TimeOfDay.fromDateTime(widget.appointment.startTime));
  }

  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }

  String _formatDateForInput(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _formatTimeForInput(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool isDateWithin14Days(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    final difference = selected.difference(today).inDays;
    return difference >= 0 && difference <= 14;
  }

  DateTime get minDate => DateTime.now();
  DateTime get maxDate => DateTime.now().add(const Duration(days: 14));

  Future<void> selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: minDate,
      lastDate: maxDate,
      helpText: 'Select New Appointment Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF6CA6FF),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        dateController.text = _formatDateForInput(pickedDate);
      });
    }
  }

  Future<void> selectTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      helpText: 'Select New Appointment Time',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF6CA6FF),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
        timeController.text = _formatTimeForInput(pickedTime);
      });
    }
  }

  bool get isFormValid {
    return selectedDate != null &&
        selectedTime != null &&
        isDateWithin14Days(selectedDate!);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveAuthLayout(
      title: 'Reschedule Appointment',
      description: 'Update the date and time of your appointment',
      showBackButton: true,
      formContent: Consumer<AppointmentProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: "Reschedule Appointment",
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColor,
                ),
                kGap8,
                CustomText(
                  text: "Update the date and time below",
                  color: AppColors.hintColor,
                ),
                kGap30,

                // Current Appointment Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: 'Current Appointment',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor,
                      ),
                      kGap8,
                      CustomText(
                        text: widget.appointment.formattedDateTime,
                        fontSize: 14,
                        color: AppColors.hintColor,
                      ),
                    ],
                  ),
                ),
                kGap30,

                // New Date
                _field(
                  context,
                  "New Appointment Date",
                  controller: dateController,
                  readOnly: true,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  onTap: () => selectDate(context),
                  prefixIcon: Icon(Icons.calendar_today, color: AppColors.hintColor),
                ),
                if (selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: CustomText(
                      text: isDateWithin14Days(selectedDate!)
                          ? '✓ Date is within 14 days'
                          : '✗ Date must be within 14 days from today',
                      fontSize: 12,
                      color: isDateWithin14Days(selectedDate!)
                          ? Colors.green
                          : AppColors.error,
                    ),
                  ),

                // New Time
                _field(
                  context,
                  "New Appointment Time",
                  controller: timeController,
                  readOnly: true,
                  suffixIcon: const Icon(Icons.access_time),
                  onTap: () => selectTime(context),
                  prefixIcon: Icon(Icons.access_time, color: AppColors.hintColor),
                ),

                kGap30,

                // Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      kGap12,
                      Expanded(
                        child: CustomText(
                          text: 'New date must be within 14 days from today',
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                kGap30,

                // Update Button
                CustomButton(
                  text: "Reschedule Appointment",
                  isLoading: provider.isLoading,
                  onPressed: provider.isLoading || !isFormValid
                      ? null
                      : () async {
                          if (selectedDate == null || selectedTime == null) return;

                          final success = await provider.updateAppointment(
                            appointmentId: widget.appointment.id,
                            doctorEmail: widget.appointment.doctorAssigned,
                            patientEmail: widget.appointment.patientBooked,
                            newDate: _formatDateForApi(selectedDate!),
                            newTime: _formatTimeForInput(selectedTime!),
                          );

                          if (context.mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Appointment rescheduled successfully ✅"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Get.back();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(provider.error ?? 'Failed to reschedule appointment'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  backgroundColor: provider.isLoading || !isFormValid
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.primary,
                ),

                if (provider.error != null) ...[
                  kGap16,
                  CustomText(
                    text: provider.error!,
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _field(
    BuildContext context,
    String label, {
    required TextEditingController controller,
    bool readOnly = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextField(
        label: label,
        hintText: label,
        controller: controller,
        readOnly: readOnly,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        onTap: onTap,
      ),
    );
  }
}

