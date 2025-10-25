import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';

import '../../../../shared_widgets/otp_text_field.dart';
import '../../registration/views/patient_registration.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({Key? key}) : super(key: key);

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isButtonEnabled = false;
  bool _isLoading = false;

  // Check if all fields are filled
  void _validateOTP() {
    setState(() {
      _isButtonEnabled =
          _otpControllers.every((controller) => controller.text.isNotEmpty);
    });
  }

  void _onVerifyPressed() async {
    FocusScope.of(context).unfocus();

    final otp = _otpControllers.map((e) => e.text).join();

    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    // Example validation logic
    if (otp == "123456") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Verified Successfully ✅")),
      );
      Get.to(CompleteProfileView());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP. Please try again ❌")),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focus in _focusNodes) {
      focus.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints:
                  BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_outlined, size: 24),
                        ),
                        kGap32,

                        // Title
                        CustomText(
                          text: "Verify Your Email",
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textColor,
                        ),
                        kGap8,
                        CustomText(
                          text:
                          "We’ve sent a 6-digit code to your email address.",
                          color: AppColors.hintColor,
                          fontSize: 14,
                        ),
                        kGap40,

                        // OTP Fields
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return OtpTextField(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              onChanged: (value) {
                                if (value.isNotEmpty && index < 5) {
                                  FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                                } else if (value.isEmpty && index > 0) {
                                  FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                                }
                                _validateOTP();
                              },
                              autoFocus: index == 0,
                            );
                          }),
                        ),

                        kGap16,

                        // Resend option
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CustomText(
                              text: "Didn’t get the code?",
                              color: AppColors.textColor,
                              fontSize: 14,
                            ),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("OTP Resent Successfully")),
                                );
                              },
                              child: CustomText(
                                text: " Resend",
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Verify Button
                        CustomButton(
                          text: _isLoading ? "Verifying..." : "Verify",
                          isLoading: _isLoading,
                          onPressed: _isButtonEnabled && !_isLoading
                              ? _onVerifyPressed
                              : null,
                          backgroundColor: _isButtonEnabled
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(.5),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


