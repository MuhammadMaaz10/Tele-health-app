 import 'package:flutter/material.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/features/auth/services/auth_api.dart';

class LoginProvider extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? error;

  final AuthApi _authApi = AuthApi();

  LoginProvider() {
    // Add listeners to text controllers to notify when text changes
    emailController.addListener(_onTextChanged);
    passwordController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    notifyListeners();
  }

  bool get isFormValid {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    return email.isNotEmpty && password.isNotEmpty;
  }

  Future<bool> login() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _authApi.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
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
    passwordController.removeListener(_onTextChanged);
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
 }