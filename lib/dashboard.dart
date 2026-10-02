import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:belajar/color.dart';
import 'package:belajar/controllers/auth_controller.dart';
import 'package:belajar/login.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? initialStudentData;

  const DashboardScreen({super.key, this.initialStudentData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SupabaseClient? get supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? studentData;
  bool isLoadingStudent = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialStudentData != null) {
      studentData = widget.initialStudentData;
      isLoadingStudent = false;
    }
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final client = supabase;
    if (client != null) {
      final user = client.auth.currentUser;
      if (user != null) {
        try {
          final userEmail = user.email?.trim() ?? '';
          final name = (user.userMetadata?['full_name'] ??
                  user.userMetadata?['name'] ??
                  studentData?['Nama'] ??
                  '')
              .toString()
              .trim();

          List<dynamic> res = [];

          // 1. Cari berdasarkan email yang terhubung
          if (userEmail.isNotEmpty) {
            res = await client
                .from('siswa')
                .select('*, Kota:id_kota(Nama)')
                .eq('email', userEmail)
                .order('id', ascending: false)
                .limit(1);
          }

          // 2. Fallback pencarian berdasarkan nama jika email belum terisi
          if (res.isEmpty && name.isNotEmpty) {
            res = await client
                .from('siswa')
                .select('*, Kota:id_kota(Nama)')
                .ilike('Nama', name)
                .order('id', ascending: false)
                .limit(1);
          }

          if (res.isNotEmpty && mounted) {
            setState(() {
              studentData = res.first;
            });
          }
        } catch (e) {
          debugPrint("Error loading student profile: $e");
        }
      }
    }

    if (mounted) {
      setState(() {
        isLoadingStudent = false;
      });
    }
  }

  Future<void> _logout() async {
    if (Get.isRegistered<AuthController>()) {
      await Get.find<AuthController>().signOut();
    } else {
      final client = supabase;
      if (client != null) {
        try {
          await client.auth.signOut();
        } catch (_) {}
      }
      Get.offAll(() => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = supabase;
    final user = client?.auth.currentUser;
    final displayName = studentData?['Nama'] ??
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email?.split('@').first ??
        'Pengguna';
    final userEmail = studentData?['email'] ?? user?.email ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Dashboard Siswa',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: MainColor.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Card with UNNES Logo & Welcome Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MainColor.primaryColor,
                    MainColor.secondaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: MainColor.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/Logo-Transparan-Warna-1.png',
                      height: 52,
                      width: 52,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.school,
                          size: 40,
                          color: MainColor.primaryColor,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selamat Datang,',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_user_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                userEmail,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Profile Information Section
            Text(
              "Informasi Profil Siswa",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: MainColor.primaryColor,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: isLoadingStudent
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            color: MainColor.primaryColor,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          _buildProfileRow(
                            icon: Icons.person_outline,
                            label: 'Nama Lengkap',
                            value: studentData?['Nama'] ?? displayName,
                          ),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _buildProfileRow(
                            icon: Icons.email_outlined,
                            label: 'Email Siswa',
                            value: userEmail,
                          ),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _buildProfileRow(
                            icon: Icons.badge_outlined,
                            label: 'NIS',
                            value: studentData?['Nis'] ?? '-',
                          ),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _buildProfileRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Tanggal Lahir',
                            value: studentData?['TanggalLahir'] ?? '-',
                          ),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _buildProfileRow(
                            icon: Icons.wc_outlined,
                            label: 'Jenis Kelamin',
                            value: studentData?['JenisKelamin'] == true
                                ? 'Laki-laki'
                                : (studentData?['JenisKelamin'] == false
                                    ? 'Perempuan'
                                    : '-'),
                          ),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _buildProfileRow(
                            icon: Icons.location_city_outlined,
                            label: 'Kota Asal',
                            value: studentData?['Kota']?['Nama'] ??
                                (studentData?['id_kota'] != null
                                    ? 'Kota #${studentData?['id_kota']}'
                                    : '-'),
                          ),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _buildProfileRow(
                            icon: Icons.home_outlined,
                            label: 'Alamat',
                            value: studentData?['Alamat'] ?? '-',
                          ),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _buildProfileRow(
                            icon: Icons.phone_outlined,
                            label: 'No. HP Orang Tua / Wali',
                            value: studentData?['Nortu'] ?? '-',
                          ),
                        ],
                      ),
              ),
            ),


            const SizedBox(height: 28),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                key: const Key('btn_logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 20),
                label: const Text(
                  'Keluar / Logout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MainColor.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: MainColor.primaryColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
