
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';

import '../../widgets/availability.dart';
import '../../widgets/basic_info.dart';
import '../../widgets/pending_approval.dart';
import '../../widgets/professional_details.dart';
import '../controller/doctor_registration_provider.dart';


class DoctorRegistrationView extends StatelessWidget {
  const DoctorRegistrationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorRegistrationProvider(),
      child: Consumer<DoctorRegistrationProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: provider.previousStep,
                          child: const Icon(Icons.arrow_back_outlined),
                        ),
                        const Spacer(),
                        CustomText(
                          text: "${provider.currentStep + 1}/4",
                          color: AppColors.hintColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: PageView(
                        controller: provider.pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          const BasicInfoStep(),
                          const ProfessionalDetailsStep(),
                          AvailabilityStep(),
                          PendingApprovalStep(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
