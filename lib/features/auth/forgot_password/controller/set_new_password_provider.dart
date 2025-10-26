
import 'package:flutter/material.dart';

class SetNewPasswordProvider extends ChangeNotifier {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? errorNewPassword;
  String? errorConfirmPassword;

  bool get obscureNewPassword => _obscureNewPassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;

  bool get isFormValid =>
      newPasswordController.text.isNotEmpty &&
          confirmPasswordController.text.isNotEmpty &&
          newPasswordController.text == confirmPasswordController.text &&
          newPasswordController.text.length >= 6;

  void toggleNewPasswordVisibility() {
    _obscureNewPassword = !_obscureNewPassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void validatePasswords() {
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (newPass.isEmpty) {
      errorNewPassword = "Enter a new password";
    } else if (newPass.length < 6) {
      errorNewPassword = "Password must be at least 6 characters";
    } else {
      errorNewPassword = null;
    }

    if (confirmPass.isEmpty) {
      errorConfirmPassword = "Confirm your password";
    } else if (confirmPass != newPass) {
      errorConfirmPassword = "Passwords do not match";
    } else {
      errorConfirmPassword = null;
    }

    notifyListeners();
  }

  void submit(BuildContext context) {
    validatePasswords();
    if (!isFormValid) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password updated successfully!")),
    );
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}

