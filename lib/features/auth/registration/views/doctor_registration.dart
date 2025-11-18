
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';

import '../../widgets/availability.dart';
import '../../widgets/basic_info.dart';
import '../../widgets/pending_approval.dart';
import '../../widgets/professional_details.dart';
import '../controller/doctor_registration_provider.dart';
import '../../otp_verification/views/otp_view.dart';


class DoctorRegistrationView extends StatelessWidget {
  final String email;
  final String role;
  
  const DoctorRegistrationView({Key? key, required this.email, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = DoctorRegistrationProvider();
        provider.setEmail(email);
        provider.setRole(role);
        return provider;
      },
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
                          text: "${provider.currentStep + 1}/3",
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
                          // const BasicInfoStep(),
                          const ProfessionalDetailsStep(),
                          PendingApprovalStep(email: email, role: role),
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
