import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/ui/snackbar_service.dart';
import 'core/network/api_factory.dart';
import 'core/utils/shared_preferences_service.dart';
import 'features/auth/forgot_password/controller/forgot_password_provider.dart';
import 'features/auth/forgot_password/controller/set_new_password_provider.dart';
import 'features/auth/login/controller/login_controller.dart';
import 'features/auth/login/view/login_view.dart';
import 'features/auth/registration/controller/doctor_registration_provider.dart';
import 'features/auth/registration/controller/patient_profile_provider.dart';
import 'features/auth/registration/controller/sign_up_provider.dart';
import 'features/profile/controller/profile_provider.dart';
import 'features/appointments/controller/appointment_provider.dart';
import 'core/navigation/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // IMPORTANT: Set token BEFORE creating providers to ensure it's available for API calls
  // This is especially critical on web/desktop where reload can cause timing issues
  final token = await SharedPreferencesService.getToken();
  if (token != null && token.isNotEmpty) {
    ApiFactory.setAuthToken(token);
    // Verify token was set (important for web persistence)
    debugPrint('✅ Token initialized on app start: ${token.substring(0, 20)}...');
  } else {
    debugPrint('⚠️ No token found on app start');
    ApiFactory.clearAuthToken();
  }

  runApp(
    DevicePreview(
      enabled: false, // ✅ Only active in debug mode
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SignUpProvider()),
          ChangeNotifierProvider(create: (_) => LoginProvider()),
          ChangeNotifierProvider(create: (_) => ForgotPasswordProvider()),
          ChangeNotifierProvider(create: (_) => PatientProfileProvider()),
          ChangeNotifierProvider(create: (_) => SetNewPasswordProvider()),
          ChangeNotifierProvider(create: (_) => DoctorRegistrationProvider()),
          ChangeNotifierProvider(create: (_) => ProfileProvider()),
          ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await SharedPreferencesService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Telehealth Services App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // ✅ Add DevicePreview properties
      builder: DevicePreview.appBuilder,
      locale: DevicePreview.locale(context),

      scaffoldMessengerKey: SnackbarService.scaffoldMessengerKey,

      home: _isLoggedIn ? const MainNavigation() : LoginView(),
    );
  }
}
