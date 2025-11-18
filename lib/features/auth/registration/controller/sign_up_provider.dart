import 'package:flutter/cupertino.dart';
import 'package:telehealth_app/core/network/network_exceptions.dart';
import 'package:telehealth_app/features/auth/services/auth_api.dart';

class SignUpProvider extends ChangeNotifier {
  final emailController = TextEditingController();
  String? selectedRole; // 'Patient', 'Doctor', or 'Nurse'
  bool isLoading = false;
  String? error;

  final AuthApi _authApi = AuthApi();

  bool get isFormValid {
    return emailController.text.trim().isNotEmpty && selectedRole != null;
  }

  void setRole(String role) {
    selectedRole = role;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> checkUser() async {
    if (!isFormValid) {
      error = 'Please select a role and enter your email';
      notifyListeners();
      return null;
    }

    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      // Send role in uppercase to API
      final response = await _authApi.checkUser(
        email: emailController.text.trim(),
        role: selectedRole!.toUpperCase(),
      );
      return response;
    } on NetworkExceptions catch (e) {
      error = e.message;
      return null;
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