class AppEndpoints {
  static const String baseUrl = "https://spatz-app.com/api"; // Update to your backend

  // Auth
  static const String login = "$baseUrl/login";
  static const String signup = "$baseUrl/auth/signup";
  static const String forgotPassword = "$baseUrl/sendCode";
  static const String verifyOtp = "$baseUrl/auth/verify-otp";
  static const String resetPassword = "$baseUrl/auth/reset-password";

  // Registration
  static const String registerPatient = "$baseUrl/patient/register";
  static const String registerDoctor = "$baseUrl/doctor/register";
  static const String registerNurse = "$baseUrl/nurse/register";
}
