import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';
import 'features/auth/forgot_password/controller/forgot_password_provider.dart';
import 'features/auth/forgot_password/controller/set_new_password_provider.dart';
import 'features/auth/login/controller/login_controller.dart';
import 'features/auth/login/view/login_view.dart';
import 'features/auth/registration/controller/doctor_registration_provider.dart';
import 'features/auth/registration/controller/patient_profile_provider.dart';
import 'features/auth/registration/controller/sign_up_provider.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !bool.fromEnvironment('dart.vm.product'), // ✅ Only active in debug mode
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SignUpProvider()),
          ChangeNotifierProvider(create: (_) => LoginProvider()),
          ChangeNotifierProvider(create: (_) => ForgotPasswordProvider()),
          ChangeNotifierProvider(create: (_) => PatientProfileProvider()),
          ChangeNotifierProvider(create: (_) => SetNewPasswordProvider()),
          ChangeNotifierProvider(create: (_) => DoctorRegistrationProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Telehealth Services App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // ✅ Add DevicePreview properties
      builder: DevicePreview.appBuilder,
      locale: DevicePreview.locale(context),

      home: LoginView(),
    );
  }
}
