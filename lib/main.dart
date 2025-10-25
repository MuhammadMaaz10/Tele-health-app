import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';
import 'features/auth/login/controller/login_controller.dart';
import 'features/auth/login/view/login_view.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !bool.fromEnvironment('dart.vm.product'), // ✅ Only active in debug mode
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LoginController()),
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
