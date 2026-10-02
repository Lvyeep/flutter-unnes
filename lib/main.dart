import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:belajar/color.dart';
import 'package:belajar/config/env_config.dart';
import 'package:belajar/controllers/auth_controller.dart';
import 'package:belajar/dashboard.dart';
import 'package:belajar/login.dart';
import 'package:belajar/page/lengkapi_data_screen.dart';
import 'package:belajar/page/splashscreen.dart';
import 'package:belajar/signup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment config (.env)
  await EnvConfig.init();

  // Initialize Supabase with values from EnvConfig
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    publishableKey: EnvConfig.supabaseAnonKey,
  );

  // Initialize Global Auth Controller
  Get.put(AuthController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistem Siswa UNNES',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: MainColor.primaryColor,
          primary: MainColor.primaryColor,
          secondary: MainColor.secondaryColor,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: AppBarTheme(
          backgroundColor: MainColor.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/signup', page: () => const SignupScreen()),
        GetPage(name: '/lengkapi-data', page: () => const LengkapiDataScreen()),
        GetPage(name: '/dashboard', page: () => const DashboardScreen()),
      ],
      unknownRoute: GetPage(name: '/not-found', page: () => const SplashScreen()),
      home: const SplashScreen(),
    );
  }
}

