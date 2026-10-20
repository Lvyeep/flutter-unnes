import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  SupabaseClient? get supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? studentData;
  bool isLoadingStudent = true;
  int _selectedTab = 0; // 0: Dashboard, 1: Jadwalku, 2: Presensi

  // State Kalender Interaktif
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  // Helper normalisasi tanggal agar perbandingan DateTime pada Map akurat tanpa jam/menit
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Dummy data lokal daftar kegiatan siswa
  late final Map<DateTime, List<String>> _kegiatanEvents = {
    // Hari ini
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day): [
      '09:00 WIB - Kelas Basis Data',
      '13:00 WIB - Praktikum Jaringan Komputer',
      '23:59 WIB - Deadline Pengumpulan Tugas',
    ],
    // Besok
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).add(const Duration(days: 1)): [
      '10:00 WIB - Rekayasa Perangkat Lunak',
      '14:00 WIB - Bimbingan Akademik',
    ],
    // 3 hari lagi
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).add(const Duration(days: 3)): [
      '08:00 WIB - Pemrograman Mobile',
      '20:00 WIB - Quiz Online Kecerdasan Buatan',
    ],
    // 2 hari lalu
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).subtract(const Duration(days: 2)): [
      '09:30 WIB - Sistem Operasi',
      '15:00 WIB - Diskusi Kelompok Himpunan',
    ],
    // Tanggal 23 di bulan yang aktif
    DateTime(DateTime.now().year, DateTime.now().month, 23): [
      '09:00 WIB - Kelas Basis Data (Ibu Sevi)',
      '13:30 WIB - Diskusi Kelompok Tugas Besar',
    ],
  };

  List<String> _getEventsForDay(DateTime day) {
    return _kegiatanEvents[_normalizeDate(day)] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
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

  String _getFirstName(String fullName) {
    final clean = fullName.trim();
    if (clean.isEmpty) return 'Mahasiswa';
    final parts = clean.split(RegExp(r'\s+'));
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final client = supabase;
    final user = client?.auth.currentUser;
    final fullName = studentData?['Nama'] ??
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email?.split('@').first ??
        'Vin';
    final firstName = _getFirstName(fullName);
    final userEmail = studentData?['email'] ?? user?.email ?? '-';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF1E1E20),
      drawer: _buildAppDrawer(fullName, userEmail),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Top Header (Dark Navy Blue)
                  _buildHeader(firstName),

                  // Top Section (White Banner & Tabs)
                  _buildTopWhiteSection(),

                  // Bottom Section (Dark Grid of 4 Action Cards)
                  _buildBottomActionGrid(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Top Dark Blue Header
  Widget _buildHeader(String firstName) {
    return Container(
      color: const Color(0xFF040836),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 14,
        left: 14,
        right: 18,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hamburger Menu Icon
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 30),
            tooltip: 'Menu & Profil',
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          const SizedBox(width: 8),

          // Title: Halo [Nama] & Mahasiswa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Halo $firstName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Mahasiswa',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Profile Avatar Icon
          InkWell(
            onTap: _showProfileBottomSheet,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(
                Icons.account_circle,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Top White Section with Pill Navigation & Next Class Banner
  Widget _buildTopWhiteSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3 Pill Navigation Tabs
          Row(
            children: [
              _buildTabPill(index: 0, label: 'Dashboard'),
              const SizedBox(width: 8),
              _buildTabPill(index: 1, label: 'Jadwalku'),
              const SizedBox(width: 8),
              _buildTabPill(index: 2, label: 'Presensi'),
            ],
          ),
          const SizedBox(height: 16),

          // Tab Content switcher
          if (_selectedTab == 0)
            _buildNextClassBanner()
          else if (_selectedTab == 1)
            _buildJadwalkuView()
          else
            _buildPresensiView(),
        ],
      ),
    );
  }

  /// Pill Tab Item
  Widget _buildTabPill({required int index, required String label}) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? const Color(0xFF070B3E) : const Color(0xFFD0D5DD),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF070B3E).withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF070B3E) : const Color(0xFF344054),
            ),
          ),
        ),
      ),
    );
  }

  /// Banner "Kelas Berikutnya" with split layout (Grey Info on Left, Calendar & Catatan on Right)
  Widget _buildNextClassBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 440;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNextClassInfoCard(),
              const SizedBox(height: 12),
              _buildCalendarAndNotesContainer(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _buildNextClassInfoCard(),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 7,
              child: _buildCalendarAndNotesContainer(),
            ),
          ],
        );
      },
    );
  }

  /// Info Card "Kelas Berikutnya"
  Widget _buildNextClassInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E4E8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Kelas Berikutnya',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Minggu 23 Agustus,\n09:00',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF151515),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sesi kelas akan diisi oleh dosen ibu Sevi dengan matakuliah Basis Data',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF4A4A4A),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),

          // Yellow Arrow Button
          InkWell(
            onTap: () {
              _showNextClassDetailModal();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE5BE3B),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE5BE3B).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Container Kalender Interaktif & Catatan Kegiatan (Menggantikan Gambar Ilustrasi)
  Widget _buildCalendarAndNotesContainer() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInteractiveCalendar(),
          const SizedBox(height: 8),
          _buildCatatanKegiatanSection(),
        ],
      ),
    );
  }

  /// Widget Kalender Interaktif menggunakan TableCalendar
  Widget _buildInteractiveCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      eventLoader: _getEventsForDay,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF070B3E),
        ),
        leftChevronIcon: Icon(Icons.chevron_left, size: 18, color: Color(0xFF070B3E)),
        rightChevronIcon: Icon(Icons.chevron_right, size: 18, color: Color(0xFF070B3E)),
        leftChevronPadding: EdgeInsets.zero,
        rightChevronPadding: EdgeInsets.zero,
        headerPadding: EdgeInsets.symmetric(vertical: 4),
        leftChevronMargin: EdgeInsets.zero,
        rightChevronMargin: EdgeInsets.zero,
      ),
      daysOfWeekHeight: 18,
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
        weekendStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFFEF4444),
        ),
      ),
      rowHeight: 28,
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
        weekendTextStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
        outsideTextStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        todayDecoration: BoxDecoration(
          color: const Color(0xFF070B3E).withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF070B3E),
        ),
        selectedDecoration: const BoxDecoration(
          color: Color(0xFF070B3E),
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        markerDecoration: const BoxDecoration(
          color: Color(0xFFE5BE3B),
          shape: BoxShape.circle,
        ),
        markersMaxCount: 1,
        markerSize: 5,
        markerMargin: const EdgeInsets.only(top: 2),
        cellMargin: const EdgeInsets.all(1),
        cellPadding: EdgeInsets.zero,
      ),
    );
  }

  /// Section Catatan Kegiatan di bawah kalender
  Widget _buildCatatanKegiatanSection() {
    final selected = _selectedDay ?? _focusedDay;
    final events = _getEventsForDay(selected);
    final dateFormatted = '${selected.day}/${selected.month}/${selected.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 12, thickness: 1, color: Color(0xFFF1F5F9)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Catatan Kegiatan',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF070B3E),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF070B3E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                dateFormatted,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF070B3E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(Icons.event_busy_rounded, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Jadwal Kosong / Tidak ada kegiatan',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...events.map(
            (event) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4, right: 6),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF070B3E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      event,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Jadwalku Tab View
  Widget _buildJadwalkuView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: MainColor.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Jadwal Kuliah Pekan Ini',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildScheduleItem('Senin, 08:00 - 10:30', 'Pemrograman Mobile', 'Lab Komputer 3', 'Dr. Budi Santoso'),
          const Divider(height: 16),
          _buildScheduleItem('Rabu, 10:00 - 12:30', 'Rekayasa Perangkat Lunak', 'Ruang Teori B.2', 'Prof. Anita Wijaya'),
          const Divider(height: 16),
          _buildScheduleItem('Minggu, 09:00 - 11:30', 'Basis Data (Praktikum)', 'Lab Database', 'Ibu Sevi, M.Kom.'),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String time, String subject, String room, String lecturer) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6, right: 10),
          decoration: BoxDecoration(
            color: MainColor.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                '$time • $room',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              Text(
                lecturer,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Presensi Tab View
  Widget _buildPresensiView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kehadiran Semester Ini',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '98.5% Hadir',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.985,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8CE68C)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          const Text(
            'Presensi aktif terbuka untuk mata kuliah berikutnya: Basis Data.',
            style: TextStyle(fontSize: 12, color: Color(0xFF555555)),
          ),
        ],
      ),
    );
  }


  /// Bottom Section: Dark Slate Background with 2x2 Grid Action Cards
  Widget _buildBottomActionGrid() {
    return Container(
      color: const Color(0xFF222224),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Row 1: Perpustakaan (Green) & Status UKT (Pink)
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Perpustakaan',
                  icon: Icons.menu_book_rounded,
                  backgroundColor: const Color(0xFF8CE68C),
                  onTap: _showPerpustakaanModal,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _buildActionCard(
                  title: 'Status UKT',
                  iconWidget: _buildPhoneCheckIcon(),
                  backgroundColor: const Color(0xFFE58CE5),
                  onTap: _showStatusUktModal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Row 2: Kartu Rencana Studi (Yellow) & KHS & Nilai (Blue)
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Kartu Rencana\nStudi',
                  icon: Icons.assignment_outlined,
                  backgroundColor: const Color(0xFFE5DD7F),
                  onTap: _showKrsModal,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _buildActionCard(
                  title: 'KHS & Nilai',
                  icon: Icons.description_outlined,
                  backgroundColor: const Color(0xFF8F9FE8),
                  onTap: _showKhsModal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Custom icon matching the Figma "Phone with checkmark" icon for Status UKT
  Widget _buildPhoneCheckIcon() {
    return Container(
      width: 32,
      height: 42,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1E1E1E), width: 2.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 2,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const Icon(
            Icons.check_rounded,
            size: 20,
            color: Color(0xFF1E1E1E),
          ),
        ],
      ),
    );
  }

  /// Unified Action Card Widget
  Widget _buildActionCard({
    required String title,
    IconData? icon,
    Widget? iconWidget,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return AspectRatio(
      aspectRatio: 1.32,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.black.withValues(alpha: 0.1),
          highlightColor: Colors.black.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.18),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Icon
                iconWidget ??
                    Icon(
                      icon,
                      size: 38,
                      color: const Color(0xFF1E1E1E),
                    ),

                // Bottom Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
                    height: 1.15,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MODALS & ACTIONS
  // ==========================================

  void _showNextClassDetailModal() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5BE3B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school_rounded, color: Color(0xFFC79810)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Detail Kelas Berikutnya',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Mata Kuliah', 'Basis Data (3 SKS)'),
            _buildDetailRow('Waktu', 'Minggu, 23 Agustus 2026 - 09:00 WIB'),
            _buildDetailRow('Dosen Pengampu', 'Ibu Sevi, M.Kom.'),
            _buildDetailRow('Ruang / Platform', 'Lab Komputer 2 / Zoom Kelas A'),
            _buildDetailRow('Topik Pembahasan', 'Normalisasi Relasional & SQL Joins'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF040836),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Get.back(),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showPerpustakaanModal() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8CE68C).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Perpustakaan Digital',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Buku Dipinjam Saat Ini:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bookmark_outline_rounded, color: Color(0xFF2E7D32)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sistem Manajemen Basis Data Modern', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Jatuh tempo: 28 Agustus 2026', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF040836),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Get.back(),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showStatusUktModal() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE58CE5).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle_outline, color: Color(0xFF8E24AA)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Status Pembayaran UKT',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Semester', 'Ganjil 2026/2027'),
            _buildDetailRow('Golongan UKT', 'Golongan 3 (Reguler)'),
            _buildDetailRow('Tagihan', 'Rp 2.500.000'),
            _buildDetailRow('Status', 'LUNAS (Terverifikasi Bank)'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF040836),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Get.back(),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showKrsModal() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5DD7F).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF7E7514)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Kartu Rencana Studi (KRS)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Total SKS Diambil', '21 SKS'),
            _buildDetailRow('Status Validasi', 'Disetujui Dosen Wali'),
            const SizedBox(height: 10),
            const Text('Daftar Mata Kuliah:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            _buildKrsItem('Basis Data', '3 SKS'),
            _buildKrsItem('Pemrograman Mobile', '3 SKS'),
            _buildKrsItem('Rekayasa Perangkat Lunak', '3 SKS'),
            _buildKrsItem('Kecerdasan Buatan', '3 SKS'),
            _buildKrsItem('Jaringan Komputer', '3 SKS'),
            _buildKrsItem('Metodologi Penelitian', '3 SKS'),
            _buildKrsItem('Kewirausahaan Teknologi', '3 SKS'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF040836),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Get.back(),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildKrsItem(String title, String sks) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('• $title', style: const TextStyle(fontSize: 12.5)),
          Text(sks, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showKhsModal() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8F9FE8).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFF3949AB)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Kartu Hasil Studi (KHS)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Indeks Prestasi Semester (IPS)', '3.88'),
            _buildDetailRow('Indeks Prestasi Kumulatif (IPK)', '3.82'),
            _buildDetailRow('Total SKS Lulus', '72 SKS'),
            _buildDetailRow('Predikat', 'Dengan Pujian (Cumlaude)'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF040836),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Get.back(),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showProfileBottomSheet() {
    final client = supabase;
    final user = client?.auth.currentUser;
    final fullName = studentData?['Nama'] ??
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email?.split('@').first ??
        'Pengguna';
    final userEmail = studentData?['email'] ?? user?.email ?? '-';

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFF040836),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      fullName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      userEmail,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              _buildDetailRow('NIS', studentData?['Nis'] ?? '-'),
              _buildDetailRow('Tanggal Lahir', studentData?['TanggalLahir'] ?? '-'),
              _buildDetailRow(
                'Jenis Kelamin',
                studentData?['JenisKelamin'] == true
                    ? 'Laki-laki'
                    : (studentData?['JenisKelamin'] == false ? 'Perempuan' : '-'),
              ),
              _buildDetailRow(
                'Kota Asal',
                studentData?['Kota']?['Nama'] ??
                    (studentData?['id_kota'] != null ? 'Kota #${studentData?['id_kota']}' : '-'),
              ),
              _buildDetailRow('Alamat', studentData?['Alamat'] ?? '-'),
              _buildDetailRow('No. HP Orang Tua', studentData?['Nortu'] ?? '-'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Get.back();
                    _logout();
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Keluar / Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  /// App Navigation Drawer
  Widget _buildAppDrawer(String fullName, String userEmail) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF040836),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF040836), size: 40),
            ),
            accountName: Text(
              fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(userEmail),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            selected: _selectedTab == 0,
            onTap: () {
              setState(() => _selectedTab = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Jadwalku'),
            selected: _selectedTab == 1,
            onTap: () {
              setState(() => _selectedTab = 1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('Presensi'),
            selected: _selectedTab == 2,
            onTap: () {
              setState(() => _selectedTab = 2);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.menu_book_rounded),
            title: const Text('Perpustakaan'),
            onTap: () {
              Navigator.pop(context);
              _showPerpustakaanModal();
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment_rounded),
            title: const Text('Status UKT'),
            onTap: () {
              Navigator.pop(context);
              _showStatusUktModal();
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: const Text('Kartu Rencana Studi'),
            onTap: () {
              Navigator.pop(context);
              _showKrsModal();
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('KHS & Nilai'),
            onTap: () {
              Navigator.pop(context);
              _showKhsModal();
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Keluar / Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
