import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:telehealth_app/core/auth/auth_debug_log.dart';
import 'package:telehealth_app/core/auth/auth_error_mapper.dart';

class SignUpProvider extends ChangeNotifier {
  final emailController = TextEditingController();
  String? selectedRole; // 'Patient', 'Doctor', or 'Nurse'
  bool isLoading = false;
  String? error;

  SignUpProvider() {
    emailController.addListener(_onEmailChanged);
  }

  bool get isFormValid {
    return emailController.text.trim().isNotEmpty && selectedRole != null;
  }

  void _onEmailChanged() {
    if (error != null) error = null;
    notifyListeners();
  }

  void setRole(String role) {
    selectedRole = role;
    if (error != null) error = null;
    notifyListeners();
  }

  /// Uses Supabase RPC [app_check_signup_email] (see database/rpc_app_check_signup_email.sql).
  /// Response shape matches the old REST API: `{ "data": { "status", "message" } }`.
  Future<Map<String, dynamic>?> checkUser() async {
    if (!isFormValid) {
      error = 'Please select a role and enter your email';
      notifyListeners();
      return null;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    final email = emailController.text.trim();

    authDebug('SignUpRPC', 'start app_check_signup_email', 'email=$email');
    try {
      final raw = await Supabase.instance.client.rpc(
        'app_check_signup_email',
        params: {'p_email': email},
      );
      authDebug('SignUpRPC', 'rpc raw response type=${raw.runtimeType}', raw);

      final Map<String, dynamic> map;
      if (raw is Map) {
        map = Map<String, dynamic>.from(raw);
      } else if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) {
          error = 'Unexpected response from server. Try again.';
          return null;
        }
        map = Map<String, dynamic>.from(decoded);
      } else {
        error = 'Unexpected response from server. Try again.';
        return null;
      }
      final status = map['status'] as String?;
      final message = map['message'] as String? ?? '';
      authDebug('SignUpRPC', 'parsed status/message', 'status=$status message=$message');

      final response = <String, dynamic>{
        'data': <String, dynamic>{
          'status': status,
          'message': message,
        },
      };

      return response;
    } on AuthException catch (e, st) {
      authDebugException('SignUpRPC', e, st);
      final friendly = userMessageForAuthException(e, flow: AuthFlow.signup);
      authDebug('SignUpRPC', 'mapped user message', friendly);
      error = friendly;
      return null;
    } catch (e, st) {
      authDebugException('SignUpRPC', e, st);
      final text = e.toString();
      if (text.contains('app_check_signup_email') ||
          text.contains('function') && text.contains('does not exist')) {
        error =
            'Server setup incomplete. Run database/rpc_app_check_signup_email.sql in Supabase SQL Editor.';
      } else {
        error = text;
      }
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.removeListener(_onEmailChanged);
    emailController.dispose();
    super.dispose();
  }
}
