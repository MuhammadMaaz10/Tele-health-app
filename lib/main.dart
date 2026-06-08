import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'core/ui/snackbar_service.dart';
import 'core/supabase/supabase_bootstrap.dart';
import 'core/supabase/supabase_session_sync.dart';
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

  try {
    await initializeSupabase();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final session = Supabase.instance.client.auth.currentSession;
    await SupabaseSessionSync.applySession(session);

    if (session != null) {
      debugPrint('✅ Supabase session restored');
    } else {
      debugPrint('⚠️ No Supabase session on app start');
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
  } catch (e, st) {
    debugPrint('[AppInitError] $e');
    debugPrint('$st');
    runApp(_StartupErrorApp(error: e.toString()));
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              'App failed to initialize.\n\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      SupabaseSessionSync.applySession(data.session);
    });
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    final session = Supabase.instance.client.auth.currentSession;
    await SupabaseSessionSync.applySession(session);
    final isLoggedIn = session != null;
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
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
      routes: {
        '/MainNavigation': (_) => const MainNavigation(),
      },

      home: _isLoggedIn ? const MainNavigation() : LoginView(),
    );
  }
}
