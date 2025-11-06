import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/features/auth/services/auth_api.dart';

import '../view/set_new_password_view.dart';

class ForgotPasswordProvider extends ChangeNotifier {
  final emailController = TextEditingController();
  String? errorText;
  bool isLoading = false;

  final AuthApi _authApi = AuthApi();

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
      await _authApi.forgotPassword(email: emailController.text.trim());
      Get.to(const SetNewPasswordView());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP sent successfully to your email!")),
      );
    } on NetworkExceptions catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
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