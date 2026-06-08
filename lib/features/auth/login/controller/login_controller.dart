import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:telehealth_app/core/auth/auth_debug_log.dart';
import 'package:telehealth_app/core/auth/auth_error_mapper.dart';
import 'package:telehealth_app/core/supabase/auth_email_check.dart';

class LoginProvider extends ChangeNotifier {
  final emailController = TextEditingController();
  bool isLoading = false;
  String? error;

  LoginProvider() {
    emailController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    notifyListeners();
  }

  bool get isFormValid {
    final email = emailController.text.trim();
    return email.isNotEmpty;
  }

  Future<bool> sendOtp() async {
    isLoading = true;
    error = null;
    notifyListeners();
    final email = emailController.text.trim();
    authDebug('LoginOTP', 'start sendOtp', 'email=$email shouldCreateUser=false');
    try {
      final check = await fetchSignupEmailStatus(email);
      if (check.status != SignupEmailStatus.exists) {
        error = 'Invalid credentials.';
        return false;
      }

      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      authDebug('LoginOTP', 'signInWithOtp completed OK (OTP email should be sent)');
      return true;
    } on AuthException catch (e, st) {
      authDebugException('LoginOTP', e, st);
      final friendly = userMessageForAuthException(e, flow: AuthFlow.loginSendOtp);
      authDebug('LoginOTP', 'mapped user message', friendly);
      error = friendly;
      return false;
    } catch (e, st) {
      authDebugException('LoginOTP', e, st);
      error = 'Could not verify account. Try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.removeListener(_onTextChanged);
    emailController.dispose();
    super.dispose();
  }
}