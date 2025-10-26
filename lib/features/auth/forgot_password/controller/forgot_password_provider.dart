import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../view/set_new_password_view.dart';

class ForgotPasswordProvider extends ChangeNotifier {
  final emailController = TextEditingController();
  String? errorText;

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

  void submit(BuildContext context) {
    validateEmail(emailController.text);
    if (errorText != null) return;

    Get.to(SetNewPasswordView());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("OTP sent successfully to your email!")),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}