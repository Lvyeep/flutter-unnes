import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:belajar/color.dart';
import 'package:belajar/controllers/auth_controller.dart';
import 'package:belajar/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Tampilkan Splash Screen
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);

    // Cek jika sedang dalam proses pemulihan kata sandi (dari tautan email / recovery redirect)
    if (authController.isResettingPassword ||
        (kIsWeb && (Uri.base.toString().contains('recovery') || Uri.base.fragment.contains('type=recovery')))) {
      authController.isResettingPassword = true;
      authController.forgotPasswordStep.value = 3;
      Get.offAll(() => const LoginScreen(), transition: Transition.fadeIn);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        authController.openForgotPasswordModal(step: 3);
      });
      return;
    }

    var session = Supabase.instance.client.auth.currentSession;
    var user = Supabase.instance.client.auth.currentUser;

    // Jika di platform web dan URL memiliki param 'code' (kembali dari OAuth redirect),
    // tunggu hingga Supabase menyelesaikan penukaran auth code PKCE menjadi session.
    if (session == null && kIsWeb && Uri.base.queryParameters.containsKey('code')) {
      int retries = 0;
      while (session == null && retries < 6) {
        await Future.delayed(const Duration(milliseconds: 500));
        session = Supabase.instance.client.auth.currentSession;
        user = Supabase.instance.client.auth.currentUser;
        retries++;
      }
    }

    if (!mounted) return;

    if (session != null && user != null) {
      await authController.handleSuccessfulAuth(user);
    } else {
      Get.offAll(
        () => const LoginScreen(),
        transition: Transition.fadeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MainColor.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                "assets/Logo-Transparan-Warna-1.png",
                height: 110,
                width: 110,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.school,
                    size: 80,
                    color: MainColor.primaryColor,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "SISTEM SISWA UNNES",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: MainColor.primaryColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Universitas Negeri Semarang",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 36),
            CircularProgressIndicator(
              color: MainColor.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
