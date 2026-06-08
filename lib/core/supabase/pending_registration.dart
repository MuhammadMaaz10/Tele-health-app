/// When true, [VerifyEmailView] must save the matching registration form via Supabase after OTP.
class PendingRegistration {
  PendingRegistration._();

  static bool completePatientProfileAfterOtp = false;
  static bool completeDoctorProfileAfterOtp = false;

  static void clear() {
    completePatientProfileAfterOtp = false;
    completeDoctorProfileAfterOtp = false;
  }
}
