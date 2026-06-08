import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/text_field.dart';
import 'package:telehealth_app/shared_widgets/responsive_auth_layout.dart';
import 'package:telehealth_app/shared_widgets/searchable_dropdown.dart';
import '../controller/create_appointment_provider.dart';
import '../controller/appointment_provider.dart';

class CreateAppointmentView extends StatelessWidget {
  const CreateAppointmentView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveAuthLayout(
      title: 'Create Appointment',
      description: 'Schedule a new appointment with your patient',
      showBackButton: true,
      formContent: Consumer<CreateAppointmentProvider>(
        builder: (context, provider, child) {
          final isDoctorFlow = provider.isDoctorFlow;
          final isPatientFlow = provider.isPatientFlow;
          final isPatientDropdownEnabled =
              !provider.isLoadingPatients && provider.patients.isNotEmpty;
          final isDoctorDropdownEnabled =
              !provider.isLoadingDoctors && provider.doctors.isNotEmpty;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: "Create Appointment",
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColor,
                ),
                kGap8,
                CustomText(
                  text: "Fill in the details below to schedule an appointment",
                  color: AppColors.hintColor,
                ),
                kGap30,

                if (isDoctorFlow)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CustomText(
                      text: 'Patient',
                      color: AppColors.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                if (isDoctorFlow)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SearchableUserDropdown(
                      label: "Patient Email",
                      hintText: provider.isLoadingPatients
                          ? "Loading patients..."
                          : "Search and select a patient",
                      users: provider.patients,
                      isLoading: provider.isLoadingPatients,
                      selectedUser: provider.selectedPatient,
                      onUserSelected: (user) {
                        provider.setSelectedPatient(user);
                      },
                      enabled: isPatientDropdownEnabled,
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.hintColor),
                    ),
                  ),

                if (isPatientFlow)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CustomText(
                      text: 'Doctor',
                      color: AppColors.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                if (isPatientFlow)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SearchableUserDropdown(
                      label: "Doctor Email",
                      hintText: provider.isLoadingDoctors
                          ? "Loading doctors..."
                          : "Search and select a doctor",
                      users: provider.doctors,
                      isLoading: provider.isLoadingDoctors,
                      selectedUser: provider.selectedDoctor,
                      onUserSelected: (user) {
                        provider.setSelectedDoctor(user);
                      },
                      enabled: isDoctorDropdownEnabled,
                      prefixIcon: Icon(Icons.medical_services_outlined, color: AppColors.hintColor),
                    ),
                  ),

                // Description
                _field(
                  context,
                  "Description",
                  controller: provider.descriptionController,
                  prefixIcon: Icon(Icons.description_outlined, color: AppColors.hintColor),
                ),

                // Date
                _field(
                  context,
                  "Appointment Date",
                  controller: provider.dateController,
                  readOnly: true,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  onTap: () => provider.selectDate(context),
                  prefixIcon: Icon(Icons.calendar_today, color: AppColors.hintColor),
                ),

                // Time
                _field(
                  context,
                  "Appointment Time",
                  controller: provider.timeController,
                  readOnly: true,
                  suffixIcon: const Icon(Icons.access_time),
                  onTap: () => provider.selectTime(context),
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
                          text: 'Appointments must be scheduled within 14 days from today',
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                kGap30,

                // Create Button
                CustomButton(
                  text: "Create Appointment",
                  isLoading: provider.isLoading,
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          final success = await provider.createAppointment();
                          if (context.mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Appointment created successfully ✅"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Refresh appointments list if we came from there
                              try {
                                final appointmentProvider =
                                    Provider.of<AppointmentProvider>(context, listen: false);
                                await appointmentProvider.loadAppointments();
                              } catch (e) {
                                // Provider might not be available
                              }
                              Get.back();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(provider.error ?? 'Failed to create appointment'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  backgroundColor: provider.isLoading
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
    TextInputType? keyboardType,
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
        keyboardType: keyboardType,
        readOnly: readOnly,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        onTap: onTap,
      ),
    );
  }
}

