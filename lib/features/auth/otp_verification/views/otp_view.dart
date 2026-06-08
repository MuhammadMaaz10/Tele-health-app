import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:telehealth_app/core/auth/auth_debug_log.dart';
import 'package:telehealth_app/core/auth/auth_error_mapper.dart';
import 'package:telehealth_app/core/supabase/pending_registration.dart';
import 'package:telehealth_app/core/theme/app_colors.dart';
import 'package:telehealth_app/core/utils/app_sizing.dart';
import 'package:telehealth_app/shared_widgets/app_button.dart';
import 'package:telehealth_app/shared_widgets/custom_text.dart';
import 'package:telehealth_app/shared_widgets/responsive_auth_layout.dart';
import 'package:telehealth_app/core/navigation/main_navigation.dart';
import 'package:telehealth_app/core/supabase/supabase_session_sync.dart';
import 'package:telehealth_app/features/auth/registration/controller/doctor_registration_provider.dart';
import 'package:telehealth_app/features/auth/registration/controller/patient_profile_provider.dart';

class VerifyEmailView extends StatefulWidget {
  final String email;
  final bool isRegistration;

  /// Passed for registration OTP: `true` when [auth.users] must be created (new email).
  final bool shouldCreateAuthUser;

  const VerifyEmailView({
    Key? key,
    required this.email,
    this.isRegistration = false,
    this.shouldCreateAuthUser = false,
  }) : super(key: key);

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  final TextEditingController _otpController = TextEditingController();

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

    authDebug(
      'VerifyOTP',
      'start verifyOTP',
      'email=${widget.email.trim()} isRegistration=${widget.isRegistration} tokenLen=${otp.trim().length}',
    );
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: widget.email.trim(),
        token: otp.trim(),
        type: OtpType.email,
      );
      authDebug('VerifyOTP', 'verifyOTP OK, applying session');

      await SupabaseSessionSync.applySession(
        Supabase.instance.client.auth.currentSession,
      );
      authDebug('VerifyOTP', 'session applied');

      try {
        if (PendingRegistration.completePatientProfileAfterOtp) {
          PendingRegistration.completePatientProfileAfterOtp = false;
          authDebug('VerifyOTP', 'saving pending PATIENT profile');
          await context.read<PatientProfileProvider>().savePatientProfileToSupabase(context);
        } else if (PendingRegistration.completeDoctorProfileAfterOtp) {
          PendingRegistration.completeDoctorProfileAfterOtp = false;
          authDebug('VerifyOTP', 'saving pending DOCTOR/NURSE profile');
          await context.read<DoctorRegistrationProvider>().saveDoctorProfileToSupabase(context);
        }
      } catch (e, st) {
        authDebugException('VerifyOTP', e, st);
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Could not save your profile. Fix issues and try again.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile save failed: $e')),
          );
        }
        return;
      }

      authDebug('VerifyOTP', 'navigating to MainNavigation');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP Verified Successfully ✅")),
        );
        Get.offAll(() => const MainNavigation());
      }
    } on AuthException catch (e, st) {
      authDebugException('VerifyOTP', e, st);
      final friendly = userMessageForAuthException(e, flow: AuthFlow.verifyOtp);
      authDebug('VerifyOTP', 'mapped user message', friendly);
      setState(() {
        _error = friendly;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendly)),
        );
      }
    } catch (e, st) {
      authDebugException('VerifyOTP', e, st);
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
                    authDebug(
                      'VerifyOTP',
                      'resend signInWithOtp',
                      'email=${widget.email.trim()} shouldCreateUser=${widget.shouldCreateAuthUser}',
                    );
                    await Supabase.instance.client.auth.signInWithOtp(
                      email: widget.email.trim(),
                      shouldCreateUser: widget.shouldCreateAuthUser,
                    );
                    authDebug('VerifyOTP', 'resend OK');

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("OTP Resent Successfully")),
                      );
                    }
                  } on AuthException catch (e, st) {
                    authDebugException('VerifyOTP', e, st);
                    final friendly =
                        userMessageForAuthException(e, flow: AuthFlow.resendOtp);
                    authDebug('VerifyOTP', 'resend mapped message', friendly);
                    setState(() {
                      _error = friendly;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(friendly)),
                      );
                    }
                  } catch (e, st) {
                    authDebugException('VerifyOTP', e, st);
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


