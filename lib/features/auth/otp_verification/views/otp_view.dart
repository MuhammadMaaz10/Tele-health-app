import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/responsive_auth_layout.dart';
import 'package:telehealth_app/features/auth/services/auth_api.dart';
import 'package:telehealth_app/core/utils/shared_preferences_service.dart';
import 'package:telehealth_app/core/navigation/main_navigation.dart';
import 'package:telehealth_app/core/network/api_factory.dart';

class VerifyEmailView extends StatefulWidget {
  final String email;
  final bool isRegistration; // To determine which OTP verification endpoint to use

  const VerifyEmailView({Key? key, required this.email, this.isRegistration = false}) : super(key: key);

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  final TextEditingController _otpController = TextEditingController();
  final AuthApi _authApi = AuthApi();

  bool _isButtonEnabled = false;
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Listen to controller changes to handle paste operations
    _otpController.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final text = _otpController.text;
    // If text length exceeds 6, trim it to 6 digits
    if (text.length > 6) {
      final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length > 6) {
        _otpController.value = TextEditingValue(
          text: digitsOnly.substring(0, 6),
          selection: TextSelection.collapsed(offset: 6),
        );
      }
    }
    _validateOTP(_otpController.text);
  }

  // Check if all fields are filled
  void _validateOTP(String? value) {
    setState(() {
      _isButtonEnabled = value != null && value.length == 6;
      _error = null;
    });
  }

  void _onVerifyPressed() async {
    FocusScope.of(context).unfocus();

    final otp = _otpController.text;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> response;
      if (widget.isRegistration) {
        response = await _authApi.verifyRegisterOtp(email: widget.email, otp: otp);
      } else {
        response = await _authApi.verifyLoginOtp(email: widget.email, otp: otp);
      }

      // Extract token and role from response
      final String? token = response['token'] as String?;
      final String? role = response['role'] as String?;

      if (token != null && token.isNotEmpty) {
        // Save token, email, and role to SharedPreferences
        await SharedPreferencesService.saveToken(token);
        await SharedPreferencesService.saveEmail(widget.email);
        if (role != null) {
          await SharedPreferencesService.saveRole(role);
        }
        // Set token in API factory for authenticated requests
        ApiFactory.setAuthToken(token);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP Verified Successfully ✅")),
        );
        // Navigate to main navigation (with bottom nav bar)
        Get.offAll(() => const MainNavigation());
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
    _otpController.removeListener(_handleTextChange);
    _otpController.dispose();
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
          Pinput(
            length: 6,
            controller: _otpController,
            defaultPinTheme: PinTheme(
              width: 56,
              height: 56,
              textStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightBorderColor, width: 1.5),
              ),
            ),
            focusedPinTheme: PinTheme(
              width: 56,
              height: 56,
              textStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            submittedPinTheme: PinTheme(
              width: 56,
              height: 56,
              textStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
            ),
            errorPinTheme: PinTheme(
              width: 56,
              height: 56,
              textStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 2),
              ),
            ),
            pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
            showCursor: true,
            keyboardType: TextInputType.number,
            hapticFeedbackType: HapticFeedbackType.lightImpact,
            enableSuggestions: false,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onCompleted: (pin) {
              _validateOTP(pin);
            },
            onChanged: (value) {
              _validateOTP(value);
            },
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
                    if (widget.isRegistration) {
                      // Resend registration OTP
                      await _authApi.resendOtp(email: widget.email);
                    } else {
                      // Resend login OTP
                      await _authApi.login(email: widget.email);
                    }

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


