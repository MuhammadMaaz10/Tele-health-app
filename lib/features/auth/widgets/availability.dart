import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';

import '../registration/controller/doctor_registration_provider.dart';

class AvailabilityStep extends StatelessWidget {
  const AvailabilityStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorRegistrationProvider>();
    final days = provider.availability.keys.toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: "Setup Availability Hours",
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textColor,
          ),
          const SizedBox(height: 6),
          CustomText(
            text: "Fill in the details to continue",
            color: AppColors.hintColor,
          ),
          const SizedBox(height: 24),

          ...days.map((day) {
            final times = provider.availability[day]!;
            final selected = provider.selectedDays.contains(day);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: selected,
                        activeColor: AppColors.primary,
                        onChanged: (v) {
                          if (v == true) {
                            provider.selectedDays.add(day);
                          } else {
                            provider.selectedDays.remove(day);
                          }
                          provider.notifyListeners();
                        },
                      ),
                      CustomText(text: day),
                    ],
                  ),
                  if (selected)
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickTime(context, day, "start"),
                            child: _buildTimeField(
                                times["start"], "Start Time", context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickTime(context, day, "end"),
                            child:
                            _buildTimeField(times["end"], "End Time", context),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 30),
          CustomButton(
            text: "Finish",
            onPressed: provider.nextStep,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField(TimeOfDay? time, String label, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.black),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(time != null ? time.format(context) : label,
              style: TextStyle(
                  color: time != null
                      ? AppColors.textColor
                      : AppColors.hintColor)),
          const Icon(Icons.access_time, color: AppColors.hintColor, size: 18),
        ],
      ),
    );
  }

  Future<void> _pickTime(
      BuildContext context, String day, String type) async {
    final provider = context.read<DoctorRegistrationProvider>();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      provider.availability[day]![type] = picked;
      provider.notifyListeners();
    }
  }
}
