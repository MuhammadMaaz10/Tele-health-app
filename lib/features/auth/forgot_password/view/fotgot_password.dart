import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/text_field.dart';
import '../controller/forgot_password_provider.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const _ForgotPasswordBody();
  }
}

class _ForgotPasswordBody extends StatelessWidget {
  const _ForgotPasswordBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ForgotPasswordProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Arrow
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back_outlined,
                    color: AppColors.textColor, size: 24),
              ),
              kGap16,

              // Title
              CustomText(
                text: "Forget Password",
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textColor,
              ),
              kGap8,
              CustomText(
                text:
                "Enter your Email Address to reset your current password.",
                color: AppColors.hintColor,
              ),
              kGap30,

              // Email TextField
              CustomTextField(
                hintText: "Email Address",
                controller: provider.emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icon(Icons.email_outlined,
                    color: AppColors.hintColor, size: 20),
                onChanged: provider.validateEmail,
              ),
              if (provider.errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: CustomText(
                    text: provider.errorText!,
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),

              const Spacer(),

              // Send OTP Button
              CustomButton(
                text: "Send OTP",
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
