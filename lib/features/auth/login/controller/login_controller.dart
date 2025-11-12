import 'package:flutter/material.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/features/auth/services/auth_api.dart';

class LoginProvider extends ChangeNotifier {
  final emailController = TextEditingController();
  bool isLoading = false;
  String? error;

  final AuthApi _authApi = AuthApi();

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
    try {
      await _authApi.login(email: emailController.text.trim());
      return true;
    } on NetworkExceptions catch (e) {
      error = e.message;
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