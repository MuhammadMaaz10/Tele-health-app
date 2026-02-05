class AppEndpoints {
  static const String baseUrl = "https://mydaktari-d96cf4ffe1d1.herokuapp.com/api"; // Update to your backend

  // Auth
  static const String login = "$baseUrl/auth/initiate-login";
  static const String signup = "$baseUrl/auth/check-email";
  static const String checkUser = "$baseUrl/auth/check-email"; // Check if user exists
  static const String resendOtp = "$baseUrl/auth/resend-otp";
  static const String verifyLoginOtp = "$baseUrl/auth/verify-login-otp";
  static const String verifyRegistrationOtp = "$baseUrl/auth/verify-registration-otp";
  static const String resetPassword = "$baseUrl/auth/reset-password";
  static const String forgotPassword = "$baseUrl/sendCode";
  // Registration
  static const String registerPatient = "$baseUrl/auth/register-patient";
  static const String registerDoctor = "$baseUrl/auth/register-practioner";
  static const String registerNurse = "$baseUrl/auth/register-practioner";
  
  // Profile
  static const String getProfile = "$baseUrl/auth/getProfile";
  static const String updateUser = "$baseUrl/auth/update-user";
  
  // Appointments
  static const String createAppointment = "$baseUrl/schedule/create";
  static const String getMyAppointments = "$baseUrl/schedule/my-appointments";
  static const String updateAppointment = "$baseUrl/schedule/update";
  static const String cancelAppointment = "$baseUrl/schedule/cancel-appointment";
  static const String confirmAppointment = "$baseUrl/schedule/confirm-appointment";
  static const String addAppointmentNotes = "$baseUrl/appointment";
  static const String getAppointmentNotes = "$baseUrl/appointment/get-notes-by-email";
  static const String updateAppointmentNote = "$baseUrl/appointment";
  static const String deleteAppointmentNote = "$baseUrl/appointment";
}
