import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:belajar/color.dart';
import 'package:belajar/dashboard.dart';

class CompleteProfileController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController namaController = TextEditingController();
  final TextEditingController nisController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController nortuController = TextEditingController();

  final Rx<DateTime?> tanggalLahir = Rx<DateTime?>(null);
  final RxBool jenisKelamin = true.obs; // true: Laki-laki, false: Perempuan
  final Rx<int?> selectedKotaId = Rx<int?>(null);

  final RxList<Map<String, dynamic>> kotaList = <Map<String, dynamic>>[].obs;
  final RxBool isFetchingKota = false.obs;
  final RxBool isSaving = false.obs;

  CompleteProfileController({String? initialName}) {
    if (initialName != null && initialName.isNotEmpty) {
      namaController.text = initialName;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchKotaList();
  }

  @override
  void onClose() {
    namaController.dispose();
    nisController.dispose();
    alamatController.dispose();
    nortuController.dispose();
    super.onClose();
  }

  /// Fetch cities list from Supabase 'Kota' table
  Future<void> fetchKotaList() async {
    isFetchingKota.value = true;
    try {
      final data = await supabase.from('Kota').select().order('Nama', ascending: true);
      kotaList.assignAll(List<Map<String, dynamic>>.from(data));

      if (kotaList.isNotEmpty && selectedKotaId.value == null) {
        selectedKotaId.value = kotaList.first['id'] as int?;
      }
    } catch (e) {
      debugPrint("Error fetching kota list: $e");
      Get.snackbar(
        'Peringatan',
        'Gagal memuat daftar kota: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } finally {
      isFetchingKota.value = false;
    }
  }

  /// Select date of birth with DatePicker
  Future<void> pickTanggalLahir(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: tanggalLahir.value ?? DateTime(2005, 1, 1),
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

    if (pickedDate != null) {
      tanggalLahir.value = pickedDate;
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return "Pilih Tanggal Lahir";
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  /// Validate form inputs and submit to Supabase 'siswa' table
  Future<void> saveStudentData() async {
    final nama = namaController.text.trim();
    final nis = nisController.text.trim();
    final alamat = alamatController.text.trim();
    final nortu = nortuController.text.trim();
    final tglLahir = tanggalLahir.value;
    final kotaId = selectedKotaId.value;

    if (nama.isEmpty) {
      _showWarning("Nama Lengkap tidak boleh kosong!");
      return;
    }
    if (nis.isEmpty) {
      _showWarning("NIS tidak boleh kosong!");
      return;
    }
    if (tglLahir == null) {
      _showWarning("Silakan pilih Tanggal Lahir Anda!");
      return;
    }
    if (alamat.isEmpty) {
      _showWarning("Alamat tidak boleh kosong!");
      return;
    }
    if (nortu.isEmpty) {
      _showWarning("Nomor kontak Orang Tua / Wali tidak boleh kosong!");
      return;
    }
    if (kotaId == null) {
      _showWarning("Silakan pilih Kota asal!");
      return;
    }

    isSaving.value = true;
    try {
      final formattedTgl = formatDate(tglLahir);

      // Insert record into Supabase 'siswa' table and fetch created profile
      final userEmail = supabase.auth.currentUser?.email;
      final inserted = await supabase.from('siswa').insert({
        'Nama': nama,
        'email': userEmail,
        'Nis': nis,
        'TanggalLahir': formattedTgl,
        'JenisKelamin': jenisKelamin.value,
        'Alamat': alamat,
        'Nortu': nortu,
        'id_kota': kotaId,
      }).select('*, Kota:id_kota(Nama)');

      final newStudentData = inserted.isNotEmpty ? inserted.first : null;

      Get.snackbar(
        'Berhasil Menyimpan!',
        'Data siswa berhasil disimpan. Selamat datang!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: MainColor.primaryColor,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        duration: const Duration(seconds: 3),
      );

      // Navigate to Dashboard
      Get.offAll(() => DashboardScreen(initialStudentData: newStudentData));
    } catch (e) {
      debugPrint("Error saving student data: $e");
      Get.snackbar(
        'Gagal Menyimpan Data',
        'Terjadi kesalahan saat menyimpan data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isSaving.value = false;
    }
  }

  void _showWarning(String message) {
    Get.snackbar(
      'Form Belum Lengkap',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
    );
  }
}
