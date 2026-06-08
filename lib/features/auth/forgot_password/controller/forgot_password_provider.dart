import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:telehealth_app/core/auth/auth_error_mapper.dart';

import '../view/set_new_password_view.dart';

class ForgotPasswordProvider extends ChangeNotifier {
  final emailController = TextEditingController();
  String? errorText;
  bool isLoading = false;

  bool get isValidEmail {
    final email = emailController.text.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  bool get isFormValid => emailController.text.trim().isNotEmpty && isValidEmail;

  void validateEmail(String value) {
    if (value.isEmpty) {
      errorText = "Email is required";
    } else if (!isValidEmail) {
      errorText = "Enter a valid email address";
    } else {
      errorText = null;
    }
    notifyListeners();
  }

  Future<void> submit(BuildContext context) async {
    validateEmail(emailController.text);
    if (errorText != null) return;

    isLoading = true;
    notifyListeners();
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        emailController.text.trim(),
      );
      if (context.mounted) {
        Get.to(const SetNewPasswordView());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Check your email for the reset link. After opening it, set your new password on the next screen if you are signed in.',
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userMessageForAuthException(e, flow: AuthFlow.signup),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
