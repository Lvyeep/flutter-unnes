import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:belajar/color.dart';
import 'package:belajar/dashboard.dart';
import 'package:belajar/login.dart';

class SignupScreen extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;

  const SignupScreen({super.key, this.initialName, this.initialEmail});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  late final TextEditingController nameController;
  late final TextEditingController emailController;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nisController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController nortuController = TextEditingController();

  DateTime? tanggalLahir;
  bool jenisKelamin = true; // true = Laki-laki, false = Perempuan
  int? selectedKotaId;

  // Dropdown bertingkat Fakultas & Prodi
  int? selectedFakultasId;
  List<Map<String, dynamic>> fakultasList = [];
  bool isFetchingFakultas = false;

  int? selectedProdiId;
  List<Map<String, dynamic>> prodiList = [];
  bool isFetchingProdi = false;

  // Semester
  int? selectedSemester;

  List<Map<String, dynamic>> kotaList = [];
  bool isFetchingKota = false;
  bool passwordVisible = false;
  bool isLoading = false;

  bool get isAlreadyAuthenticated => _supabase?.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName ?? '');
    emailController = TextEditingController(
      text: widget.initialEmail ?? _supabase?.auth.currentUser?.email ?? '',
    );
    _fetchKotaList();
    _fetchFakultasList();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nisController.dispose();
    alamatController.dispose();
    nortuController.dispose();
    super.dispose();
  }

  /// Helper untuk membaca nama Fakultas (mendukung kolom 'nama_fakultas' atau 'nama')
  String _getFakultasName(Map<String, dynamic> f) {
    return (f['nama_fakultas'] ?? f['nama'] ?? 'Fakultas #${f['id']}')
        .toString();
  }

  /// Helper untuk membaca nama Prodi (mendukung kolom 'nama_prodi' atau 'nama')
  String _getProdiName(Map<String, dynamic> p) {
    return (p['nama_prodi'] ?? p['nama'] ?? 'Prodi #${p['id']}').toString();
  }

  /// Helper untuk membaca nama Kota (mendukung kolom 'Nama' atau 'nama')
  String _getKotaName(Map<String, dynamic> k) {
    return (k['Nama'] ?? k['nama'] ?? 'Kota #${k['id']}').toString();
  }

  /// 1. Fetch daftar Fakultas dari Supabase
  Future<void> _fetchFakultasList() async {
    final client = _supabase;
    if (client == null) return;

    setState(() {
      isFetchingFakultas = true;
    });

    try {
      final data = await client
          .from('fakultas')
          .select()
          .order('id', ascending: true);

      if (mounted) {
        final list = List<Map<String, dynamic>>.from(data);
        // Urutkan berdasarkan nama secara lokal
        list.sort((a, b) => _getFakultasName(a).compareTo(_getFakultasName(b)));

        setState(() {
          fakultasList = list;
        });
      }
    } catch (e) {
      debugPrint("Error fetching fakultas list: $e");
      if (mounted) {
        Get.snackbar(
          'Gagal Memuat Fakultas',
          'Tidak dapat memuat daftar fakultas: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isFetchingFakultas = false;
        });
      }
    }
  }

  /// 2. Fetch daftar Prodi berdasarkan id_fakultas yang dipilih
  Future<void> _fetchProdiList(int fakultasId) async {
    final client = _supabase;
    if (client == null) return;

    setState(() {
      isFetchingProdi = true;
      selectedProdiId = null; // Reset prodi yang terpilih sebelumnya
      prodiList = [];
    });

    try {
      final data = await client
          .from('prodi')
          .select()
          .eq('id_fakultas', fakultasId)
          .order('id', ascending: true);

      if (mounted) {
        final list = List<Map<String, dynamic>>.from(data);
        // Urutkan berdasarkan nama secara lokal
        list.sort((a, b) => _getProdiName(a).compareTo(_getProdiName(b)));

        setState(() {
          prodiList = list;
        });
      }
    } catch (e) {
      debugPrint("Error fetching prodi list: $e");
      if (mounted) {
        Get.snackbar(
          'Gagal Memuat Program Studi',
          'Tidak dapat memuat daftar program studi: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isFetchingProdi = false;
        });
      }
    }
  }

  /// Fetch daftar Kota dari Supabase
  Future<void> _fetchKotaList() async {
    final client = _supabase;
    if (client == null) return;

    setState(() {
      isFetchingKota = true;
    });

    try {
      final data = await client
          .from('Kota')
          .select()
          .order('Nama', ascending: true);
      if (mounted) {
        setState(() {
          kotaList = List<Map<String, dynamic>>.from(data);
          if (kotaList.isNotEmpty && selectedKotaId == null) {
            selectedKotaId = kotaList.first['id'] as int?;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching kota list: $e");
    } finally {
      if (mounted) {
        setState(() {
          isFetchingKota = false;
        });
      }
    }
  }

  Future<void> _pickTanggalLahir() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: tanggalLahir ?? DateTime(2005, 1, 1),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: MainColor.primaryColor,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF212435),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      setState(() {
        tanggalLahir = pickedDate;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Pilih Tanggal Lahir";
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  void _showWarning(String msg) {
    Get.snackbar(
      'Validasi Form',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
    );
  }

  /// 4. Handler: SignUp Auth & Simpan profil lengkap ke tabel 'siswa'
  Future<void> _handleRegisterAndSave() async {
    final nama = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final nis = nisController.text.trim();
    final alamat = alamatController.text.trim();
    final nortu = nortuController.text.trim();

    // Validasi Data
    if (nama.isEmpty) {
      _showWarning("Harap masukkan Nama Lengkap!");
      return;
    }
    if (email.isEmpty) {
      _showWarning("Harap masukkan Email!");
      return;
    }
    if (!isAlreadyAuthenticated && password.length < 6) {
      _showWarning("Password minimal harus 6 karakter!");
      return;
    }
    if (nis.isEmpty) {
      _showWarning("Harap masukkan NIS (Nomor Induk Siswa)!");
      return;
    }
    if (selectedFakultasId == null) {
      _showWarning("Harap pilih Fakultas!");
      return;
    }
    if (selectedProdiId == null) {
      _showWarning("Harap pilih Program Studi (Prodi)!");
      return;
    }
    if (selectedSemester == null) {
      _showWarning("Harap pilih Semester!");
      return;
    }
    if (tanggalLahir == null) {
      _showWarning("Harap pilih Tanggal Lahir!");
      return;
    }
    if (selectedKotaId == null) {
      _showWarning("Harap pilih Kota asal!");
      return;
    }
    if (alamat.isEmpty) {
      _showWarning("Harap masukkan Alamat tempat tinggal!");
      return;
    }
    if (nortu.isEmpty) {
      _showWarning("Harap masukkan Nomor HP Orang Tua / Wali!");
      return;
    }

    final client = _supabase;
    if (client == null) {
      _showWarning("Koneksi Supabase belum terinisialisasi.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String? userId;

      // 1. Jika belum login (mendaftar akun Supabase Auth baru)
      if (!isAlreadyAuthenticated) {
        final authRes = await client.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': nama},
        );

        if (authRes.session == null && authRes.user == null) {
          throw 'Gagal membuat akun autentikasi. Silakan periksa kembali email & password Anda.';
        }
        userId = authRes.user?.id ?? client.auth.currentUser?.id;
      } else {
        userId = client.auth.currentUser?.id;
      }

      if (userId == null) {
        throw 'ID Pengguna tidak ditemukan. Silakan login terlebih dahulu.';
      }

      final formattedTgl = _formatDate(tanggalLahir);

      // Data profil siswa yang akan disimpan (sertakan 'id': userId)
      final studentPayload = {
        'id': userId,
        'Nama': nama,
        'email': email,
        'Nis': nis,
        'TanggalLahir': formattedTgl,
        'JenisKelamin': jenisKelamin,
        'Alamat': alamat,
        'Nortu': nortu,
        'id_kota': selectedKotaId,
        'id_prodi': selectedProdiId,
        'semester': selectedSemester,
        'role': 'mahasiswa',
        'status': 'aktif',
      };

      // 2. Cek apakah record siswa dengan ID user ini sudah ada (filter .eq('id', userId))
      final existing = await client
          .from('siswa')
          .select('id')
          .eq('id', userId)
          .limit(1);

      Map<String, dynamic>? savedStudentData;

      if (existing.isNotEmpty) {
        final updated = await client
            .from('siswa')
            .update(studentPayload)
            .eq('id', userId)
            .select(
              '*, Kota:id_kota(Nama), prodi:id_prodi(*, fakultas:id_fakultas(*))',
            );

        savedStudentData = updated.isNotEmpty ? updated.first : null;
      } else {
        final inserted = await client
            .from('siswa')
            .insert(studentPayload)
            .select(
              '*, Kota:id_kota(Nama), prodi:id_prodi(*, fakultas:id_fakultas(*))',
            );

        savedStudentData = inserted.isNotEmpty ? inserted.first : null;
      }

      if (!mounted) return;

      Get.snackbar(
        'Registrasi Berhasil',
        'Data mahasiswa Anda berhasil didaftarkan dan tersimpan.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: MainColor.primaryColor,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        duration: const Duration(seconds: 3),
      );

      // 3. Arahkan langsung ke Dashboard
      Get.offAll(
        () => DashboardScreen(initialStudentData: savedStudentData),
        transition: Transition.fadeIn,
      );
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Gagal Menyimpan Data',
        'Terjadi kesalahan saat registrasi: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGoogleUser = isAlreadyAuthenticated;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isGoogleUser
              ? 'Lengkapi Registrasi Mahasiswa'
              : 'Registrasi Akun Mahasiswa',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: MainColor.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: isGoogleUser
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Get.offAll(() => const LoginScreen()),
              ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [MainColor.primaryColor, MainColor.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
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
                        height: 50,
                        width: 50,
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
                          Text(
                            isGoogleUser
                                ? 'Pendaftaran Mahasiswa Baru'
                                : 'Registrasi Akun & Data Mahasiswa',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isGoogleUser
                                ? 'Lengkapi data akademik & pribadi Anda untuk langsung mengakses Dashboard.'
                                : 'Daftarkan identitas dan program studi Anda untuk mengakses sistem akademik.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header 1: Akun & Identitas Dasar
                      _buildSectionHeader(
                        icon: Icons.person_pin_rounded,
                        title: 'Identitas Diri & Akun',
                      ),
                      const SizedBox(height: 16),

                      // Field: Nama Lengkap
                      _buildFieldLabel('Nama Lengkap', isRequired: true),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('input_nama'),
                        controller: nameController,
                        style: const TextStyle(fontSize: 14),
                        decoration: _inputDecoration(
                          hint: 'Masukkan nama lengkap',
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field: Email
                      _buildFieldLabel('Email Mahasiswa', isRequired: true),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('input_email'),
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: isGoogleUser,
                        style: TextStyle(
                          fontSize: 14,
                          color: isGoogleUser
                              ? Colors.grey[700]
                              : const Color(0xFF212435),
                        ),
                        decoration: _inputDecoration(
                          hint: 'nama@domain.com',
                          icon: Icons.email_outlined,
                          suffixIcon: isGoogleUser
                              ? const Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field Password (jika belum login)
                      if (!isGoogleUser) ...[
                        _buildFieldLabel('Password', isRequired: true),
                        const SizedBox(height: 8),
                        TextField(
                          key: const Key('input_password'),
                          controller: passwordController,
                          obscureText: !passwordVisible,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Minimal 6 karakter',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
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
                              icon: Icon(
                                passwordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  passwordVisible = !passwordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Field: NIS / NIM
                      _buildFieldLabel(
                        'NIS / NIM (Nomor Induk Mahasiswa)',
                        isRequired: true,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('input_nis'),
                        controller: nisController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                        decoration: _inputDecoration(
                          hint: 'Contoh: 20261234',
                          icon: Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section Header 2: Data Akademik (Dynamic Dropdown)
                      _buildSectionHeader(
                        icon: Icons.school_rounded,
                        title: 'Data Akademik (Fakultas, Prodi & Semester)',
                      ),
                      const SizedBox(height: 16),

                      // Field: Dropdown Fakultas
                      _buildFieldLabel('Fakultas', isRequired: true),
                      const SizedBox(height: 8),
                      isFetchingFakultas
                          ? _buildLoadingDropdown(
                              hint: 'Memuat daftar fakultas...',
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedFakultasId != null
                                      ? MainColor.primaryColor.withValues(
                                          alpha: 0.5,
                                        )
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  key: const Key('dropdown_fakultas'),
                                  isExpanded: true,
                                  value: selectedFakultasId,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey[600],
                                  ),
                                  hint: const Text(
                                    'Pilih Fakultas',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  items: fakultasList.map((fakultas) {
                                    final id = fakultas['id'] as int;
                                    final namaFakultas = _getFakultasName(
                                      fakultas,
                                    );
                                    return DropdownMenuItem<int>(
                                      value: id,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.account_balance_outlined,
                                            color: MainColor.primaryColor,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              namaFakultas,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newFakultasId) {
                                    if (newFakultasId != null &&
                                        newFakultasId != selectedFakultasId) {
                                      setState(() {
                                        selectedFakultasId = newFakultasId;
                                      });
                                      // Fetch Prodi sesuai Fakultas yang dipilih
                                      _fetchProdiList(newFakultasId);
                                    }
                                  },
                                ),
                              ),
                            ),
                      const SizedBox(height: 16),

                      // Field: Dropdown Program Studi (Dynamic / Bertingkat)
                      _buildFieldLabel(
                        'Program Studi (Prodi)',
                        isRequired: true,
                      ),
                      const SizedBox(height: 8),
                      if (selectedFakultasId == null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.grey[500],
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Pilih Fakultas terlebih dahulu',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (isFetchingProdi)
                        _buildLoadingDropdown(
                          hint: 'Memuat daftar program studi...',
                        )
                      else if (prodiList.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Belum ada Program Studi untuk fakultas ini',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedProdiId != null
                                  ? MainColor.primaryColor.withValues(
                                      alpha: 0.5,
                                    )
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              key: const Key('dropdown_prodi'),
                              isExpanded: true,
                              value: selectedProdiId,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey[600],
                              ),
                              hint: const Text(
                                'Pilih Program Studi',
                                style: TextStyle(fontSize: 14),
                              ),
                              items: prodiList.map((prodi) {
                                final id = prodi['id'] as int;
                                final namaProdi = _getProdiName(prodi);
                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.school_outlined,
                                        color: MainColor.primaryColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          namaProdi,
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (newProdiId) {
                                if (newProdiId != null) {
                                  setState(() {
                                    selectedProdiId = newProdiId;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Field: Dropdown Semester
                      _buildFieldLabel('Semester Saat Ini', isRequired: true),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedSemester != null
                                ? MainColor.primaryColor.withValues(alpha: 0.5)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            key: const Key('dropdown_semester'),
                            isExpanded: true,
                            value: selectedSemester,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey[600],
                            ),
                            hint: const Text(
                              'Pilih Semester',
                              style: TextStyle(fontSize: 14),
                            ),
                            items: List.generate(8, (index) => index + 1).map((
                              sem,
                            ) {
                              return DropdownMenuItem<int>(
                                value: sem,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.format_list_numbered_rounded,
                                      color: MainColor.primaryColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Semester $sem',
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (newSem) {
                              if (newSem != null) {
                                setState(() {
                                  selectedSemester = newSem;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section Header 3: Data Diri & Kontak
                      _buildSectionHeader(
                        icon: Icons.contact_mail_outlined,
                        title: 'Data Diri & Alamat',
                      ),
                      const SizedBox(height: 16),

                      // Field: Tanggal Lahir
                      _buildFieldLabel('Tanggal Lahir', isRequired: true),
                      const SizedBox(height: 8),
                      InkWell(
                        key: const Key('btn_pick_tanggal_lahir'),
                        onTap: _pickTanggalLahir,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: tanggalLahir != null
                                  ? MainColor.primaryColor
                                  : const Color(0xFFE2E8F0),
                              width: tanggalLahir != null ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: MainColor.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _formatDate(tanggalLahir),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: tanggalLahir != null
                                        ? const Color(0xFF212435)
                                        : Colors.grey[400],
                                    fontWeight: tanggalLahir != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field: Jenis Kelamin
                      _buildFieldLabel('Jenis Kelamin', isRequired: true),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGenderChoice(
                              key: const Key('btn_gender_male'),
                              label: 'Laki-laki',
                              icon: Icons.male_rounded,
                              isSelected: jenisKelamin == true,
                              onTap: () {
                                setState(() {
                                  jenisKelamin = true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildGenderChoice(
                              key: const Key('btn_gender_female'),
                              label: 'Perempuan',
                              icon: Icons.female_rounded,
                              isSelected: jenisKelamin == false,
                              onTap: () {
                                setState(() {
                                  jenisKelamin = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Field: Kota Asal
                      _buildFieldLabel('Kota Asal', isRequired: true),
                      const SizedBox(height: 8),
                      isFetchingKota
                          ? _buildLoadingDropdown(hint: 'Memuat daftar kota...')
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  key: const Key('dropdown_kota'),
                                  isExpanded: true,
                                  value: selectedKotaId,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey[600],
                                  ),
                                  hint: const Text(
                                    'Pilih Kota Asal',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  items: kotaList.map((kota) {
                                    final id = kota['id'] as int;
                                    final namaKota = _getKotaName(kota);
                                    return DropdownMenuItem<int>(
                                      value: id,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_city,
                                            color: MainColor.primaryColor,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              namaKota,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newVal) {
                                    if (newVal != null) {
                                      setState(() {
                                        selectedKotaId = newVal;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                      const SizedBox(height: 16),

                      // Field: Alamat
                      _buildFieldLabel(
                        'Alamat Tempat Tinggal',
                        isRequired: true,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('input_alamat'),
                        controller: alamatController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14),
                        decoration: _inputDecoration(
                          hint:
                              'Contoh: Jl. Sekaran No. 1, Gunungpati, Semarang',
                          icon: Icons.home_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field: Nomor Orang Tua / Wali
                      _buildFieldLabel(
                        'Nomor HP Orang Tua / Wali',
                        isRequired: true,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('input_nortu'),
                        controller: nortuController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 14),
                        decoration: _inputDecoration(
                          hint: 'Contoh: 081234567890',
                          icon: Icons.phone_outlined,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          key: const Key('btn_submit_register'),
                          onPressed: isLoading ? null : _handleRegisterAndSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MainColor.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isGoogleUser
                                      ? 'Simpan & Masuk ke Dashboard'
                                      : 'Daftar & Simpan Data',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (!isGoogleUser) ...[
                const SizedBox(height: 20),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Sudah punya akun? ",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.offAll(() => const LoginScreen());
                        },
                        child: Text(
                          "Masuk",
                          style: TextStyle(
                            color: MainColor.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: MainColor.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDropdown({required String hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: MainColor.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF212435),
            ),
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildGenderChoice({
    Key? key,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? MainColor.primaryColor.withValues(alpha: 0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? MainColor.primaryColor
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? MainColor.primaryColor : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? MainColor.primaryColor
                      : const Color(0xFF212435),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: BorderSide(color: MainColor.primaryColor, width: 1.5),
      ),
      prefixIcon: Icon(icon, color: MainColor.primaryColor, size: 20),
      suffixIcon: suffixIcon,
    );
  }
}
