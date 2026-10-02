import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:belajar/color.dart';
import 'package:belajar/controllers/complete_profile_controller.dart';

class LengkapiDataScreen extends StatelessWidget {
  final String? initialName;

  const LengkapiDataScreen({super.key, this.initialName});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<CompleteProfileController>()
        ? Get.find<CompleteProfileController>()
        : Get.put(CompleteProfileController(initialName: initialName));
    if (initialName != null && controller.namaController.text.isEmpty) {
      controller.namaController.text = initialName!;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Lengkapi Data Siswa',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: MainColor.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with UNNES Logo
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
                            'Registrasi Data Siswa',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Silakan isi seluruh informasi profil Anda sebelum masuk ke Dashboard.',
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

              // Form Container
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
                      // Field 1: Nama Lengkap
                      _buildFieldLabel('Nama Lengkap', isRequired: true),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('input_nama'),
                        controller: controller.namaController,
                        style: const TextStyle(fontSize: 14),
                        decoration: _inputDecoration(
                          hint: 'Masukkan nama lengkap',
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field 2: NIS
                      _buildFieldLabel('NIS (Nomor Induk Siswa)', isRequired: true),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('input_nis'),
                        controller: controller.nisController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                        decoration: _inputDecoration(
                          hint: 'Contoh: 20261234',
                          icon: Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field 3: Tanggal Lahir
                      _buildFieldLabel('Tanggal Lahir', isRequired: true),
                      const SizedBox(height: 8),
                      Obx(() {
                        final date = controller.tanggalLahir.value;
                        final dateStr = controller.formatDate(date);
                        final isSelected = date != null;

                        return InkWell(
                          key: const Key('btn_pick_tanggal_lahir'),
                          onTap: () => controller.pickTanggalLahir(context),
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
                                color: isSelected
                                    ? MainColor.primaryColor
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1.0,
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
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isSelected
                                        ? const Color(0xFF212435)
                                        : Colors.grey[400],
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      // Field 4: Jenis Kelamin
                      _buildFieldLabel('Jenis Kelamin', isRequired: true),
                      const SizedBox(height: 8),
                      Obx(
                        () => Row(
                          children: [
                            Expanded(
                              child: _buildGenderChoice(
                                key: const Key('gender_male'),
                                label: 'Laki-laki',
                                icon: Icons.male_rounded,
                                isSelected: controller.jenisKelamin.value == true,
                                onTap: () => controller.jenisKelamin.value = true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGenderChoice(
                                key: const Key('gender_female'),
                                label: 'Perempuan',
                                icon: Icons.female_rounded,
                                isSelected: controller.jenisKelamin.value == false,
                                onTap: () => controller.jenisKelamin.value = false,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field 5: Kota Asal
                      _buildFieldLabel('Kota Asal', isRequired: true),
                      const SizedBox(height: 8),
                      Obx(() {
                        if (controller.isFetchingKota.value) {
                          return Container(
                            padding: const EdgeInsets.all(14),
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
                                Text(
                                  'Memuat daftar kota...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return DropdownButtonFormField<int>(
                          key: const Key('dropdown_kota'),
                          initialValue: controller.selectedKotaId.value,
                          items: controller.kotaList.map((kota) {
                            return DropdownMenuItem<int>(
                              value: kota['id'] as int,
                              child: Text(
                                kota['Nama'] ?? 'Kota',
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            controller.selectedKotaId.value = val;
                          },
                          decoration: _inputDecoration(
                            hint: 'Pilih Kota',
                            icon: Icons.location_city_outlined,
                          ),
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: MainColor.primaryColor,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: Colors.white,
                        );
                      }),
                      const SizedBox(height: 16),

                      // Field 6: Alamat
                      _buildFieldLabel('Alamat Lengkap', isRequired: true),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('input_alamat'),
                        controller: controller.alamatController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14),
                        decoration: _inputDecoration(
                          hint: 'Masukkan alamat tempat tinggal saat ini...',
                          icon: Icons.home_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field 7: Nomor Orang Tua / Wali
                      _buildFieldLabel('Nomor HP Orang Tua / Wali', isRequired: true),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('input_nortu'),
                        controller: controller.nortuController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 14),
                        decoration: _inputDecoration(
                          hint: 'Contoh: 081234567890',
                          icon: Icons.phone_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Button
              Obx(() {
                final isSaving = controller.isSaving.value;

                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    key: const Key('btn_simpan_profil'),
                    onPressed: isSaving ? null : controller.saveStudentData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MainColor.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSaving
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Menyimpan Data...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Simpan Data & Lanjutkan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF212435),
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
            color: isSelected ? MainColor.primaryColor : const Color(0xFFE2E8F0),
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
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? MainColor.primaryColor : const Color(0xFF212435),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
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
        borderSide: BorderSide(
          color: MainColor.primaryColor,
          width: 1.5,
        ),
      ),
      prefixIcon: Icon(
        icon,
        color: MainColor.primaryColor,
        size: 20,
      ),
    );
  }
}
