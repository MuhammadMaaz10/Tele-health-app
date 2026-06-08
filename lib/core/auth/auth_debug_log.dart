import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Filter logs in your IDE/console with: LoginOTP | VerifyOTP | SignUpRPC
void authDebug(String tag, String step, [Object? detail]) {
  if (detail != null) {
    debugPrint('[$tag] $step → $detail');
  } else {
    debugPrint('[$tag] $step');
  }
}

void authDebugException(String tag, Object error, [StackTrace? stack]) {
  debugPrint('[$tag] ERROR: $error');
  if (error is AuthException) {
    debugPrint('[$tag]   AuthException.message: ${error.message}');
    debugPrint('[$tag]   AuthException.code: ${error.code}');
    debugPrint('[$tag]   AuthException.statusCode: ${error.statusCode}');
  }
  if (stack != null) {
    debugPrint('[$tag]   stack: $stack');
  }
}
