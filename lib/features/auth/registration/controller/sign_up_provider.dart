import 'package:flutter/cupertino.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/features/auth/services/auth_api.dart';

class SignUpProvider extends ChangeNotifier{
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? error;

  final AuthApi _authApi = AuthApi();

  Future<bool> signup({String? role}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _authApi.signup(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        role: role,
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}