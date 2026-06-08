import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of [app_check_signup_email] (see database/rpc_app_check_signup_email.sql).
enum SignupEmailStatus { newEmail, exists, inactive }

class SignupEmailCheckResult {
  SignupEmailCheckResult({required this.status, required this.message});

  final SignupEmailStatus status;
  final String message;

  /// `true` when [signInWithOtp] should use [shouldCreateUser]: true (no auth user yet).
  bool get shouldCreateAuthUser => status == SignupEmailStatus.newEmail;
}

/// Calls RPC `app_check_signup_email` (anon-safe). Parses JSON or JSON string.
Future<SignupEmailCheckResult> fetchSignupEmailStatus(String email) async {
  final raw = await Supabase.instance.client.rpc(
    'app_check_signup_email',
    params: {'p_email': email.trim()},
  );

  final Map<String, dynamic> map;
  if (raw is Map) {
    map = Map<String, dynamic>.from(raw);
  } else if (raw is String) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw StateError('Unexpected app_check_signup_email response');
    }
    map = Map<String, dynamic>.from(decoded);
  } else {
    throw StateError('Unexpected app_check_signup_email response');
  }

  final statusStr = map['status'] as String? ?? '';
  final message = map['message'] as String? ?? '';

  switch (statusStr) {
    case 'EXISTS':
      return SignupEmailCheckResult(status: SignupEmailStatus.exists, message: message);
    case 'INACTIVE':
      return SignupEmailCheckResult(status: SignupEmailStatus.inactive, message: message);
    case 'NEW':
    default:
      return SignupEmailCheckResult(status: SignupEmailStatus.newEmail, message: message);
  }
}
