import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/text_field.dart';
import 'package:telehealth_app/shared_widgets/responsive_auth_layout.dart';
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

    return ResponsiveAuthLayout(
      title: 'Reset Your Password',
      description: 'Enter your email address and we\'ll send you a code to reset your password.',
      showBackButton: true,
      formContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: "Forget Password",
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textColor,
          ),
          kGap8,
          CustomText(
            text: "Enter your Email Address to reset your current password.",
            color: AppColors.hintColor,
          ),
          kGap30,
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
          kGap40,
          CustomButton(
            isLoading: provider.isLoading,
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
    );
  }
}
