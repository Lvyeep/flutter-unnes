import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:belajar/config/env_config.dart';
import 'package:belajar/color.dart';
import 'package:belajar/dashboard.dart';
import 'package:belajar/login.dart';
import 'package:belajar/signup.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  final SupabaseClient supabase = Supabase.instance.client;

  final RxBool isLoading = false.obs;
  final RxBool isGoogleLoading = false.obs;
  final RxBool isResetLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Forgot password reactive states
  final RxInt forgotPasswordStep = 1.obs; // 1: Email, 2: OTP, 3: New Password
  final RxString resetEmail = ''.obs;

  GoogleSignIn? _googleSignIn;
  bool _isNavigating = false;
  bool isResettingPassword = false;

  @override
  void onInit() {
    super.onInit();
    _initGoogleSignIn();
    _setupAuthStateListener();
  }

  void _initGoogleSignIn() {
    if (!kIsWeb) {
      _googleSignIn = GoogleSignIn(
        serverClientId: EnvConfig.webClientId,
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? EnvConfig.iosClientId
            : null,
        scopes: const ['email', 'profile', 'openid'],
      );
    }
  }

  void _setupAuthStateListener() {
    supabase.auth.onAuthStateChange.listen((data) {
      debugPrint("Auth state change event: ${data.event}");

      // 3. Deteksi Klik Link Email (Opsi 2 - Otomatis via onAuthStateChange)
      if (data.event == AuthChangeEvent.passwordRecovery) {
        isResettingPassword = true;
        forgotPasswordStep.value = 3;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          openForgotPasswordModal(step: 3);
        });
        return;
      }

      if (isResettingPassword) return;

      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        // Jika sedang di root/splash screen awal, biarkan SplashScreen yang menangani alurnya secara smooth.
        // Jika sedang di halaman lain (seperti login), lakukan routing.
        if (Get.currentRoute != '/' && Get.currentRoute != '/splash') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            handleSuccessfulAuth(data.session!.user);
          });
        }
      }
    });
  }

  void _safeShowSnackbar(
    String title,
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    try {
      if (Get.context != null) {
        Get.snackbar(
          title,
          message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: backgroundColor ?? MainColor.primaryColor,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: icon != null ? Icon(icon, color: Colors.white) : null,
          duration: duration,
        );
      }
    } catch (e) {
      debugPrint("Notice: could not show snackbar ($e)");
    }
  }

  User? get currentUser => supabase.auth.currentUser;

  /// Check whether the student has already registered complete data in the 'siswa' table.
  /// Checks by email first, then fallback to name.
  Future<Map<String, dynamic>?> checkExistingStudentProfile({String? email, String? name}) async {
    try {
      final userEmail = email?.trim() ?? '';
      final userName = name?.trim() ?? '';

      if (userEmail.isNotEmpty) {
        final response = await supabase
            .from('siswa')
            .select('*, Kota:id_kota(Nama)')
            .eq('email', userEmail)
            .order('id', ascending: false)
            .limit(1);

        if (response.isNotEmpty) {
          final profile = response.first;
          if (_isProfileComplete(profile)) {
            return profile;
          }
        }
      }

      if (userName.isNotEmpty) {
        final response = await supabase
            .from('siswa')
            .select('*, Kota:id_kota(Nama)')
            .ilike('Nama', userName)
            .order('id', ascending: false)
            .limit(1);

        if (response.isNotEmpty) {
          final profile = response.first;
          if (_isProfileComplete(profile)) {
            return profile;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint("Error checking student profile: $e");
      return null;
    }
  }

  bool _isProfileComplete(Map<String, dynamic> profile) {
    final hasNama =
        profile['Nama'] != null && profile['Nama'].toString().trim().isNotEmpty;
    final hasNis =
        profile['Nis'] != null && profile['Nis'].toString().trim().isNotEmpty;
    final hasTglLahir = profile['TanggalLahir'] != null &&
        profile['TanggalLahir'].toString().trim().isNotEmpty;
    final hasGender = profile['JenisKelamin'] != null;
    final hasAlamat = profile['Alamat'] != null &&
        profile['Alamat'].toString().trim().isNotEmpty;
    final hasNortu =
        profile['Nortu'] != null && profile['Nortu'].toString().trim().isNotEmpty;
    final hasKota = profile['id_kota'] != null;

    return hasNama &&
        hasNis &&
        hasTglLahir &&
        hasGender &&
        hasAlamat &&
        hasNortu &&
        hasKota;
  }

  /// Handles routing and notification after successful login
  Future<void> handleSuccessfulAuth(User user, {String? googleDisplayName}) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      final displayName = googleDisplayName ??
          user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          user.email?.split('@').first ??
          '';
      final email = user.email ?? '';

      final existingProfile = await checkExistingStudentProfile(email: email, name: displayName);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (existingProfile != null) {
          _safeShowSnackbar(
            'Login Berhasil',
            'Selamat datang kembali, $displayName!',
            backgroundColor: MainColor.primaryColor,
            icon: Icons.check_circle_outline,
            duration: const Duration(seconds: 2),
          );

          Get.offAll(
            () => DashboardScreen(initialStudentData: existingProfile),
            transition: Transition.fadeIn,
          );
        } else {
          _safeShowSnackbar(
            'Login Berhasil',
            'Silakan lengkapi pendaftaran data siswa Anda.',
            backgroundColor: MainColor.secondaryColor,
            icon: Icons.info_outline,
            duration: const Duration(seconds: 3),
          );

          Get.offAll(
            () => SignupScreen(initialName: displayName, initialEmail: email),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 400),
          );
        }
      });
    } catch (e) {
      debugPrint("Error handling successful auth: $e");
    } finally {
      _isNavigating = false;
    }
  }

  /// Sign In with Google:
  /// - Web: Supabase native OAuth signInWithOAuth
  /// - Mobile (Android/iOS): native GoogleSignIn with WEB_CLIENT from .env and signInWithIdToken
  Future<void> signInWithGoogle() async {
    isGoogleLoading.value = true;
    errorMessage.value = '';
    try {
      if (kIsWeb) {
        // Platform Web: Alur OAuth bawaan Supabase
        await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? 'http://localhost:5000' : null,
        );
        return;
      }

      // Platform Mobile (Android / iOS): Native GoogleSignIn
      try {
        await _googleSignIn?.signOut();
      } catch (_) {}

      // 1. Trigger the native Google Sign In modal/dialog
      final GoogleSignInAccount? googleUser = await _googleSignIn?.signIn();

      if (googleUser == null) {
        // User cancelled the account selection dialog
        isGoogleLoading.value = false;
        return;
      }

      // 2. Obtain auth details (idToken & accessToken)
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'ID Token Google tidak ditemukan. Pastikan Web Client ID terkonfigurasi dengan benar di file .env.';
      }

      // 3. Authenticate with Supabase using IdToken
      final AuthResponse authResponse = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = authResponse.user ?? supabase.auth.currentUser;
      if (user == null) {
        throw 'Gagal mendapatkan data user setelah login Google.';
      }

      await handleSuccessfulAuth(user, googleDisplayName: googleUser.displayName);
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      Get.snackbar(
        'Gagal Login Google',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      errorMessage.value = msg;
      Get.snackbar(
        'Terjadi Kesalahan',
        'Gagal login dengan Google: $msg',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    } finally {
      isGoogleLoading.value = false;
    }
  }

  /// Sign In with Email and Password
  Future<void> signInWithEmail(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      errorMessage.value = 'Harap masukkan email dan password!';
      Get.snackbar(
        'Validasi',
        'Harap masukkan email dan password!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = supabase.auth.currentUser;
      if (user == null) {
        throw 'User tidak ditemukan';
      }

      await handleSuccessfulAuth(user);
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      Get.snackbar(
        'Gagal Login',
        'Email atau password salah! (${e.message})',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      errorMessage.value = msg;
      Get.snackbar(
        'Terjadi Kesalahan',
        'Error: $msg',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Helper untuk membuka modal Lupa Password dari mana saja
  void openForgotPasswordModal({String? initialEmail, int step = 1}) {
    if (initialEmail != null && initialEmail.isNotEmpty) {
      resetEmail.value = initialEmail;
    }
    forgotPasswordStep.value = step;

    if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) {
      return;
    }

    Get.bottomSheet(
      const ForgotPasswordBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    );
  }

  /// 1. Kirim Email Reset (sendPasswordResetEmail):
  /// - Panggil supabase.auth.resetPasswordForEmail(email.trim(), redirectTo: 'http://localhost:5000')
  /// - Pastikan menyertakan redirectTo agar tautan di email mengarah balik ke aplikasi web.
  Future<bool> sendPasswordResetEmail(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      _safeShowSnackbar(
        'Validasi Gagal',
        'Harap masukkan alamat email Anda!',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return false;
    }

    if (!GetUtils.isEmail(trimmedEmail)) {
      _safeShowSnackbar(
        'Validasi Gagal',
        'Format email tidak valid!',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return false;
    }

    isResetLoading.value = true;
    try {
      await supabase.auth.resetPasswordForEmail(
        trimmedEmail,
        redirectTo: 'http://localhost:5000',
      );

      resetEmail.value = trimmedEmail;
      forgotPasswordStep.value = 2;

      _safeShowSnackbar(
        'Email Reset Terkirim',
        'Silakan periksa kotak masuk atau spam email Anda untuk 6 digit kode OTP atau klik tautan pemulihan.',
        backgroundColor: MainColor.primaryColor,
        icon: Icons.mark_email_read_outlined,
        duration: const Duration(seconds: 4),
      );
      return true;
    } on AuthException catch (e) {
      _safeShowSnackbar(
        'Gagal Mengirim Email Reset',
        e.message,
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
      return false;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _safeShowSnackbar(
        'Terjadi Kesalahan',
        'Gagal mengirim email reset: $msg',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
      return false;
    } finally {
      isResetLoading.value = false;
    }
  }

  /// Alias for backward compatibility
  Future<bool> sendPasswordResetOtp(String email) => sendPasswordResetEmail(email);

  /// 2. Verifikasi Kode OTP (Opsi 1 - Manual):
  /// - Panggil supabase.auth.verifyOTP(email: email.trim(), token: otp.trim(), type: OtpType.recovery)
  /// - WAJIB CEK: Pastikan response.session != null sebelum mengubah step UI ke Langkah 3.
  Future<bool> verifyOtp(String email, String otp) async {
    final trimmedEmail = email.trim();
    final trimmedOtp = otp.trim();

    if (trimmedEmail.isEmpty) {
      _safeShowSnackbar(
        'Validasi Gagal',
        'Email tidak boleh kosong!',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return false;
    }

    if (trimmedOtp.isEmpty || trimmedOtp.length < 6) {
      _safeShowSnackbar(
        'Validasi Gagal',
        'Harap masukkan 6 digit kode OTP!',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return false;
    }

    isResetLoading.value = true;
    try {
      final response = await supabase.auth.verifyOTP(
        email: trimmedEmail,
        token: trimmedOtp,
        type: OtpType.recovery,
      );

      // WAJIB CEK: Pastikan response.session != null sebelum mengubah step UI ke Langkah 3
      if (response.session == null) {
        throw const AuthException('Sesi pemulihan tidak terbentuk. Pastikan kode OTP valid dan belum kedaluwarsa.');
      }

      isResettingPassword = true;
      forgotPasswordStep.value = 3;

      _safeShowSnackbar(
        'Verifikasi Berhasil',
        'Kode OTP valid! Silakan masukkan kata sandi baru Anda.',
        backgroundColor: Colors.green.shade700,
        icon: Icons.check_circle_outline,
      );
      return true;
    } on AuthException catch (e) {
      _safeShowSnackbar(
        'Verifikasi Gagal',
        e.message,
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
      return false;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _safeShowSnackbar(
        'Terjadi Kesalahan',
        'Gagal verifikasi kode OTP: $msg',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
      return false;
    } finally {
      isResetLoading.value = false;
    }
  }

  /// Alias for backward compatibility
  Future<bool> verifyRecoveryOtp(String email, String otp) => verifyOtp(email, otp);

  /// 4. Simpan Password Baru (updatePassword):
  /// - Sebelum update, pastikan supabase.auth.currentSession != null
  /// - Panggil supabase.auth.updateUser(UserAttributes(password: newPassword.trim()))
  /// - Setelah berhasil, panggil await supabase.auth.signOut() untuk membersihkan sesi pemulihan
  Future<bool> updatePassword(String newPassword) async {
    final trimmedPassword = newPassword.trim();
    if (trimmedPassword.length < 6) {
      _safeShowSnackbar(
        'Validasi Gagal',
        'Password baru minimal harus 6 karakter!',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return false;
    }

    // WAJIB CEK: Sebelum update, pastikan supabase.auth.currentSession != null
    if (supabase.auth.currentSession == null) {
      _safeShowSnackbar(
        'Sesi Kedaluwarsa',
        'Sesi pemulihan tidak ditemukan atau telah berakhir. Silakan minta kode OTP atau tautan baru.',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
      return false;
    }

    isResetLoading.value = true;
    try {
      await supabase.auth.updateUser(
        UserAttributes(password: trimmedPassword),
      );

      // Membersihkan sesi pemulihan setelah berhasil update password
      await supabase.auth.signOut();
      isResettingPassword = false;
      forgotPasswordStep.value = 1;
      resetEmail.value = '';

      if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) {
        Get.back();
      }

      _safeShowSnackbar(
        'Password Berhasil Diperbarui',
        'Kata sandi akun Anda telah berhasil diperbarui. Silakan login kembali dengan kata sandi baru.',
        backgroundColor: Colors.green.shade700,
        icon: Icons.check_circle_outline,
        duration: const Duration(seconds: 4),
      );

      // Kembalikan user ke tampilan/halaman login utama
      Get.offAll(
        () => const LoginScreen(),
        transition: Transition.fadeIn,
      );
      return true;
    } on AuthException catch (e) {
      _safeShowSnackbar(
        'Gagal Mengubah Password',
        e.message,
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
      return false;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _safeShowSnackbar(
        'Terjadi Kesalahan',
        'Gagal memperbarui password: $msg',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
      return false;
    } finally {
      isResetLoading.value = false;
    }
  }

  /// Sign Out from Supabase and Google
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
      if (!kIsWeb && _googleSignIn != null) {
        try {
          await _googleSignIn!.signOut();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("Error signing out: $e");
    } finally {
      Get.offAll(() => const LoginScreen());
    }
  }
}
