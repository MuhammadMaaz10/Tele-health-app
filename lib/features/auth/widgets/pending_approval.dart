import 'package:flutter/material.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';

class PendingApprovalStep extends StatelessWidget {
  const PendingApprovalStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time_rounded,
                color: AppColors.primary, size: 70),
            const SizedBox(height: 20),
            CustomText(
              text: "Pending Admin Approval",
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textColor,
            ),
            const SizedBox(height: 8),
            CustomText(
              text:
              "Your account is under review by the admin. You’ll get a notification once approved.",
              textAlign: TextAlign.center,
              color: AppColors.hintColor,
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: "Finish",
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
