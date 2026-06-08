import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps [AuthException] from Supabase Auth to short, user-facing copy.
String userMessageForAuthException(AuthException e, {required AuthFlow flow}) {
  final code = e.code;
  final msg = e.message;
  final lower = msg.toLowerCase();

  // GoTrue returns code otp_disabled + "Signups not allowed for otp" when:
  // - Authentication → Settings has disabled new sign-ups, and/or
  // - Login uses shouldCreateUser:false but this email is not in auth.users yet.
  // (Must run before the otp_disabled switch case — that case is a different failure mode.)
  if (code == 'otp_disabled' && lower.contains('signups not allowed')) {
    return flow == AuthFlow.loginSendOtp
        ? 'No account for this email yet, or new sign-ups are off in Supabase. Use Create Account first, or in Dashboard: Authentication → Settings → allow new users.'
        : msg;
  }

  if (code != null) {
    switch (code) {
      case 'user_not_found':
      case 'identity_not_found':
        return flow == AuthFlow.loginSendOtp
            ? 'Invalid credentials.'
            : 'We could not find an account for this email.';
      case 'signup_disabled':
        return 'New sign-ups are disabled for this email. Contact support if you need access.';
      case 'otp_expired':
        return 'This code has expired. Request a new one.';
      case 'otp_disabled':
        return 'Email OTP sign-in is turned off in this project. Check Supabase: Authentication → Providers → Email.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'email_not_confirmed':
        return 'Please confirm your email before signing in.';
      case 'user_banned':
        return 'This account cannot sign in. Contact support.';
      case 'validation_failed':
        return 'Check your email address and try again.';
      default:
        break;
    }
  }

  if (lower.contains('signups not allowed') ||
      lower.contains('signup is disabled')) {
    return flow == AuthFlow.loginSendOtp ? 'Invalid credentials.' : msg;
  }
  if (lower.contains('user not found') || lower.contains('invalid login')) {
    return flow == AuthFlow.loginSendOtp
        ? 'Invalid credentials.'
        : 'No account found for this email. Please create an account first.';
  }
  if (lower.contains('invalid') &&
      (lower.contains('otp') || lower.contains('token') || lower.contains('code'))) {
    return 'Invalid or expired code. Request a new code and try again.';
  }

  return msg.isNotEmpty ? msg : 'Something went wrong. Please try again.';
}

enum AuthFlow {
  loginSendOtp,
  verifyOtp,
  resendOtp,
  signup,
}
