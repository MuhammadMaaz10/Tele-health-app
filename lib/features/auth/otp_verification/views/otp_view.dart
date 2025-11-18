import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/responsive_auth_layout.dart';
import 'package:telehealth_app/features/auth/services/auth_api.dart';
import 'package:telehealth_app/features/home/view/home_view.dart';

import '../../../../shared_widgets/otp_text_field.dart';

class VerifyEmailView extends StatefulWidget {
  final String email;
  final bool isRegistration; // To determine which OTP verification endpoint to use
  
  const VerifyEmailView({Key? key, required this.email, this.isRegistration = false}) : super(key: key);

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final AuthApi _authApi = AuthApi();

  bool _isButtonEnabled = false;
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;

  // Check if all fields are filled
  void _validateOTP() {
    setState(() {
      _isButtonEnabled =
          _otpControllers.every((controller) => controller.text.isNotEmpty);
      _error = null;
    });
  }

  void _onVerifyPressed() async {
    FocusScope.of(context).unfocus();

    final otp = _otpControllers.map((e) => e.text).join();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.isRegistration) {
        await _authApi.verifyRegisterOtp(email: widget.email, otp: otp);
      } else {
        await _authApi.verifyLoginOtp(email: widget.email, otp: otp);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP Verified Successfully ✅")),
        );
        // Navigate to home screen
        Get.offAll(() => const HomeView());
      }
    } on NetworkExceptions catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred. Please try again.';
        _isLoading = false;
      });
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
    return ResponsiveAuthLayout(
      title: 'Verify Your Email',
      description: 'We\'ve sent a verification code to your email address. Please enter it below to continue.',
      showBackButton: true,
      formContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: "Verify Your Email",
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textColor,
          ),
          kGap8,
          CustomText(
            text: "We've sent a 6-digit code to ${widget.email}",
            color: AppColors.hintColor,
            fontSize: 14,
          ),
          kGap40,
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
          if (_error != null) ...[
            kGap8,
            CustomText(
              text: _error!,
              color: Colors.red,
              fontSize: 12,
            ),
          ],
          kGap16,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomText(
                text: "Didn't get the code?",
                color: AppColors.textColor,
                fontSize: 14,
              ),
              GestureDetector(
                onTap: _isResending ? null : () async {
                  setState(() {
                    _isResending = true;
                    _error = null;
                  });
                  
                  try {
                    await _authApi.login(email: widget.email);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("OTP Resent Successfully")),
                      );
                    }
                  } on NetworkExceptions catch (e) {
                    setState(() {
                      _error = e.message;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message)),
                      );
                    }
                  } catch (e) {
                    setState(() {
                      _error = 'Failed to resend OTP. Please try again.';
                    });
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isResending = false;
                      });
                    }
                  }
                },
                child: CustomText(
                  text: _isResending ? " Resending..." : " Resend",
                  color: _isResending ? AppColors.hintColor : AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          kGap40,
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
    );
  }
}


