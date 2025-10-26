import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/text_field.dart';

import '../controller/set_new_password_provider.dart';


class SetNewPasswordView extends StatelessWidget {
  const SetNewPasswordView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const _SetNewPasswordBody();
  }
}

class _SetNewPasswordBody extends StatelessWidget {
  const _SetNewPasswordBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SetNewPasswordProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back_outlined,
                    color: AppColors.textColor, size: 24),
              ),
              kGap16,

              // Title
              CustomText(
                text: "Set a New Password",
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textColor,
              ),
              kGap8,
              CustomText(
                text: "Create a new strong password for your account.",
                color: AppColors.hintColor,
              ),
              kGap30,

              // New Password field
              CustomTextField(
                hintText: "Create New Password",
                controller: provider.newPasswordController,
                obscureText: provider.obscureNewPassword,
                prefixIcon: Icon(Icons.lock_outline,
                    color: AppColors.hintColor, size: 20),
                suffixIcon: GestureDetector(
                  onTap: provider.toggleNewPasswordVisibility,
                  child: Icon(
                    provider.obscureNewPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.hintColor,
                    size: 20,
                  ),
                ),
                onChanged: (_) => provider.validatePasswords(),
              ),
              if (provider.errorNewPassword != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: CustomText(
                    text: provider.errorNewPassword!,
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),

              kGap16,

              // Confirm Password field
              CustomTextField(
                hintText: "Confirm New Password",
                controller: provider.confirmPasswordController,
                obscureText: provider.obscureConfirmPassword,
                prefixIcon: Icon(Icons.lock_outline,
                    color: AppColors.hintColor, size: 20),
                suffixIcon: GestureDetector(
                  onTap: provider.toggleConfirmPasswordVisibility,
                  child: Icon(
                    provider.obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.hintColor,
                    size: 20,
                  ),
                ),
                onChanged: (_) => provider.validatePasswords(),
              ),
              if (provider.errorConfirmPassword != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: CustomText(
                    text: provider.errorConfirmPassword!,
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),

              const Spacer(),

              // Update Password Button
              CustomButton(
                text: "Update Password",
                onPressed: provider.isFormValid
                    ? () => provider.submit(context)
                    : null,
                backgroundColor: provider.isFormValid
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
