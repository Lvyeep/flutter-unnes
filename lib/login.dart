import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:belajar/color.dart';
import 'package:belajar/controllers/auth_controller.dart';
import 'package:belajar/signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool passwordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleEmailSignIn() {
    authController.signInWithEmail(
      emailController.text,
      passwordController.text,
    );
  }

  void _openForgotPasswordModal() {
    authController.openForgotPasswordModal(
      initialEmail: emailController.text.trim(),
      step: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 64 > 0 ? constraints.maxHeight - 64 : 0,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                // UNNES Logo Branding
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MainColor.primaryColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/Logo-Transparan-Warna-1.png',
                    height: 90,
                    width: 90,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.school,
                        size: 70,
                        color: MainColor.primaryColor,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Title & Subtitle
                Text(
                  "Selamat Datang",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF212435),
                      ) ??
                      const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212435),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Sistem Jadwal Mahasiswa",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ) ??
                      TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                // Input Email
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Email",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212435),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('input_email'),
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "nama@domain.com",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: MainColor.primaryColor,
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: MainColor.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Input Password
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Password",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212435),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('input_password'),
                  controller: passwordController,
                  obscureText: !passwordVisible,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Masukkan password Anda",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: MainColor.primaryColor,
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: MainColor.primaryColor,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          passwordVisible = !passwordVisible;
                        });
                      },
                      icon: Icon(
                        passwordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Lupa Password Button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('btn_forgot_password'),
                    onPressed: _openForgotPasswordModal,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "Lupa Password?",
                      style: TextStyle(
                        color: MainColor.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Error Message Display (Wrapped inside SingleChildScrollView to prevent overflow)
                Obx(() {
                  final error = authController.errorMessage.value;
                  if (error.isEmpty) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            error,
                            style: const TextStyle(
                              color: Color(0xFF991B1B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => authController.errorMessage.value = '',
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFFDC2626),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Button Login
                Obx(() {
                  final isLoading = authController.isLoading.value;
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      key: const Key('btn_login'),
                      onPressed: isLoading ? null : _handleEmailSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MainColor.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Masuk",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Divider Or
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        "atau masuk dengan",
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),

                const SizedBox(height: 20),

                // Google Sign-In Button (Opens dialog account chooser)
                Obx(() {
                  final isGoogleLoading = authController.isGoogleLoading.value;

                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      key: const Key('google_sign_in_button'),
                      onPressed: isGoogleLoading
                          ? null
                          : () => authController.signInWithGoogle(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 0,
                      ),
                      child: isGoogleLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: MainColor.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Menghubungkan Akun Google...",
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google Logo icon
                                _buildGoogleIcon(),
                                const SizedBox(width: 12),
                                const Text(
                                  "Masuk dengan Google",
                                  style: TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                }),

                const SizedBox(height: 28),

                // Navigate to Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Belum punya akun? ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(
                          () => const SignupScreen(),
                          transition: Transition.rightToLeft,
                        );
                      },
                      child: Text(
                        "Daftar Sekarang",
                        style: TextStyle(
                          color: MainColor.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  ),
),
);
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          "G",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [
                  Color(0xFF4285F4), // Blue
                  Color(0xFFEA4335), // Red
                  Color(0xFFFBBC05), // Yellow
                  Color(0xFF34A853), // Green
                ],
              ).createShader(const Rect.fromLTWH(0.0, 0.0, 24.0, 24.0)),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordBottomSheet extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordBottomSheet({
    super.key,
    this.initialEmail = '',
  });

  @override
  State<ForgotPasswordBottomSheet> createState() => _ForgotPasswordBottomSheetState();
}

class _ForgotPasswordBottomSheetState extends State<ForgotPasswordBottomSheet> {
  final AuthController authController = AuthController.to;

  late final TextEditingController _emailController;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    final email = widget.initialEmail.isNotEmpty
        ? widget.initialEmail
        : authController.resetEmail.value;
    _emailController = TextEditingController(text: email);
    if (email.isNotEmpty) {
      authController.resetEmail.value = email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    await authController.sendPasswordResetEmail(_emailController.text);
  }

  Future<void> _handleVerifyOtp() async {
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : authController.resetEmail.value;
    await authController.verifyOtp(
      email,
      _otpController.text,
    );
  }

  Future<void> _handleUpdatePassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass.isEmpty || confirmPass.isEmpty) {
      Get.snackbar(
        'Validasi Gagal',
        'Harap isi kedua kolom kata sandi!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      );
      return;
    }

    if (newPass.length < 6) {
      Get.snackbar(
        'Validasi Gagal',
        'Password baru minimal harus 6 karakter!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      );
      return;
    }

    if (newPass != confirmPass) {
      Get.snackbar(
        'Validasi Gagal',
        'Konfirmasi password tidak cocok!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      );
      return;
    }

    await authController.updatePassword(newPass);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header & Close Button
                    Obx(() {
                      final currentStep = authController.forgotPasswordStep.value;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: MainColor.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  currentStep == 1
                                      ? Icons.mail_outline_rounded
                                      : currentStep == 2
                                          ? Icons.security_rounded
                                          : Icons.lock_reset_rounded,
                                  color: MainColor.primaryColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Lupa Password",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF212435),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey, size: 22),
                            onPressed: () => Get.back(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 20),

                    // Multi-step Progress Indicator
                    _buildStepIndicator(),

                    const SizedBox(height: 24),

                    // Multi-step Content
                    _buildCurrentStepContent(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Obx(() {
      final currentStep = authController.forgotPasswordStep.value;
      return Row(
        children: [
          _buildStepItem(1, "Email", currentStep),
          _buildStepDivider(1, currentStep),
          _buildStepItem(2, "Kode OTP", currentStep),
          _buildStepDivider(2, currentStep),
          _buildStepItem(3, "Sandi Baru", currentStep),
        ],
      );
    });
  }

  Widget _buildStepItem(int step, String label, int currentStep) {
    final bool isCompleted = currentStep > step;
    final bool isActive = currentStep == step;

    final Color bgColor = isCompleted
        ? Colors.green
        : (isActive ? MainColor.primaryColor : const Color(0xFFE2E8F0));
    final Color textColor = isCompleted || isActive ? Colors.white : const Color(0xFF94A3B8);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: MainColor.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : Text(
                      "$step",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? MainColor.primaryColor : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(int afterStep, int currentStep) {
    final bool isPassed = currentStep > afterStep;
    return Container(
      width: 30,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: isPassed ? Colors.green : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildCurrentStepContent() {
    return Obx(() {
      final currentStep = authController.forgotPasswordStep.value;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _getStepWidget(currentStep),
      );
    });
  }

  Widget _getStepWidget(int step) {
    switch (step) {
      case 1:
        return _buildStep1Email();
      case 2:
        return _buildStep2Otp();
      case 3:
        return _buildStep3NewPassword();
      default:
        return _buildStep1Email();
    }
  }

  // --- Langkah 1: Input Alamat Email ---
  Widget _buildStep1Email() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Langkah 1: Masukkan Email",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212435),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Masukkan alamat email yang terdaftar pada akun Anda. Kami akan mengirimkan tautan reset kata sandi dan 6 digit kode OTP pemulihan.",
          style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
        ),
        const SizedBox(height: 20),
        const Text(
          "Alamat Email",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF212435),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('input_reset_email'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: "nama@domain.com",
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: MainColor.primaryColor, width: 1.5),
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: MainColor.primaryColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Obx(() {
          final isLoading = authController.isResetLoading.value;
          return SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              key: const Key('btn_send_otp'),
              onPressed: isLoading ? null : _handleSendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: MainColor.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Kirim Email Reset & OTP",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          );
        }),
      ],
    );
  }

  // --- Langkah 2: Input OTP 6 Digit & Petunjuk Link Email ---
  Widget _buildStep2Otp() {
    final currentEmail = authController.resetEmail.value.isNotEmpty
        ? authController.resetEmail.value
        : _emailController.text.trim();

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Langkah 2: Masukkan Kode OTP",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212435),
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
            children: [
              const TextSpan(text: "Kode OTP telah dikirimkan ke "),
              TextSpan(
                text: currentEmail,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212435),
                ),
              ),
              const TextSpan(text: ". Silakan masukkan 6 digit kode di bawah:"),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 5. Teks petunjuk link reset email
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                color: MainColor.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Atau klik tombol reset langsung di email Anda",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: MainColor.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Tautan pada email akan secara otomatis membawa Anda langsung ke langkah pembuatan kata sandi baru.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          "Kode OTP (6 Digit)",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF212435),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('input_otp'),
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
            color: Color(0xFF212435),
          ),
          decoration: InputDecoration(
            hintText: "••••••",
            counterText: "",
            hintStyle: TextStyle(
              color: Colors.grey[400],
              letterSpacing: 8,
              fontSize: 22,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: MainColor.primaryColor, width: 1.5),
            ),
            prefixIcon: Icon(
              Icons.password_rounded,
              color: MainColor.primaryColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                authController.forgotPasswordStep.value = 1;
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                "Ganti Email",
                style: TextStyle(
                  color: MainColor.secondaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Obx(() {
              final isLoading = authController.isResetLoading.value;
              return TextButton(
                onPressed: isLoading ? null : _handleSendOtp,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "Kirim Ulang Email/OTP",
                  style: TextStyle(
                    color: MainColor.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 20),
        Obx(() {
          final isLoading = authController.isResetLoading.value;
          return SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              key: const Key('btn_verify_otp'),
              onPressed: isLoading ? null : _handleVerifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: MainColor.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Verifikasi Kode OTP",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          );
        }),
      ],
    );
  }

  // --- Langkah 3: Input Password Baru & Konfirmasi ---
  Widget _buildStep3NewPassword() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Langkah 3: Simpan Kata Sandi Baru",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212435),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Buat kata sandi baru untuk akun Anda (minimal 6 karakter).",
          style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
        ),
        const SizedBox(height: 20),
        const Text(
          "Password Baru",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF212435),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('input_new_password'),
          controller: _newPasswordController,
          obscureText: !_newPasswordVisible,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: "Minimal 6 karakter",
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: MainColor.primaryColor, width: 1.5),
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: MainColor.primaryColor,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _newPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey[600],
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _newPasswordVisible = !_newPasswordVisible;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Konfirmasi Password Baru",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF212435),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('input_confirm_new_password'),
          controller: _confirmPasswordController,
          obscureText: !_confirmPasswordVisible,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: "Ulangi password baru",
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: MainColor.primaryColor, width: 1.5),
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: MainColor.primaryColor,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _confirmPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey[600],
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _confirmPasswordVisible = !_confirmPasswordVisible;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Obx(() {
          final isLoading = authController.isResetLoading.value;
          return SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              key: const Key('btn_save_new_password'),
              onPressed: isLoading ? null : _handleUpdatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: MainColor.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Simpan Password Baru",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          );
        }),
      ],
    );
  }
}
