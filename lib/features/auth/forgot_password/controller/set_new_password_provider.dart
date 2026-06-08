import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:telehealth_app/core/auth/auth_error_mapper.dart';

class SetNewPasswordProvider extends ChangeNotifier {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? errorNewPassword;
  String? errorConfirmPassword;
  bool isLoading = false;

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

  /// Requires a recovery session (after user follows the email link) or any active session.
  Future<void> submit(BuildContext context) async {
    validatePasswords();
    if (!isFormValid) return;

    if (Supabase.instance.client.auth.currentSession == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Open the password reset link from your email first, then return here.',
            ),
          ),
        );
      }
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: newPasswordController.text.trim(),
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
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
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
