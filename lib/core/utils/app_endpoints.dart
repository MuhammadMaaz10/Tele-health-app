class AppEndpoints {
  static const String baseUrl = "https://mydaktari-d96cf4ffe1d1.herokuapp.com/api"; // Update to your backend

  // Auth
  static const String login = "$baseUrl/auth/check-email";
  static const String signup = "$baseUrl/auth/signup";
  static const String checkUser = "$baseUrl/auth/check-email"; // Check if user exists
  // static const String sendOtp = "$baseUrl/auth/send-otp"; // Send OTP for login/signup
  static const String forgotPassword = "$baseUrl/sendCode";
  static const String verifyOtp = "$baseUrl/auth/verify-login-otp";
  static const String resetPassword = "$baseUrl/auth/reset-password";

  // Registration
  static const String registerPatient = "$baseUrl/patient/register";
  static const String registerDoctor = "$baseUrl/doctor/register";
  static const String registerNurse = "$baseUrl/nurse/register";
}
