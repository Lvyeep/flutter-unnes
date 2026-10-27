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

  // State Kalender & Jadwal Kuliah
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<DateTime, List<String>> _kegiatanEvents = {};
  List<Map<String, dynamic>> jadwalList = [];
  bool isLoadingJadwal = false;

  // Helper normalisasi tanggal agar perbandingan DateTime pada Map akurat tanpa jam/menit
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    try {
      return DateTime.parse(date.toString());
    } catch (_) {
      return null;
    }
  }

  String _formatTime(dynamic time) {
    if (time == null) return '--:--';
    final str = time.toString();
    final parts = str.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return str;
  }

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      case DateTime.saturday:
        return 'Sabtu';
      case DateTime.sunday:
        return 'Minggu';
      default:
        return '';
    }
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return months[date.month - 1];
  }

  List<String> _getEventsForDay(DateTime day) {
    return _kegiatanEvents[_normalizeDate(day)] ?? [];
  }

  void _populateKegiatanEvents(List<Map<String, dynamic>> list) {
    final Map<DateTime, List<String>> newEvents = {};

    for (final item in list) {
      final tglStr = item['tanggal'];
      final dt = _parseDate(tglStr);
      if (dt == null) continue;

      final normalized = _normalizeDate(dt);
      final jamMulai = _formatTime(item['jam_mulai']);
      final jamSelesai = _formatTime(item['jam_selesai']);
      final matkul = item['matkul'] as Map<String, dynamic>?;
      final namaMatkul = matkul?['nama_matkul'] ?? 'Mata Kuliah';
      final ruangan = item['ruangan'] ?? 'Ruang Kelas';

      final eventString = '$jamMulai - $jamSelesai WIB: $namaMatkul ($ruangan)';

      if (!newEvents.containsKey(normalized)) {
        newEvents[normalized] = [];
      }
      newEvents[normalized]!.add(eventString);
    }

    if (mounted) {
      setState(() {
        _kegiatanEvents = newEvents;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    if (widget.initialStudentData != null) {
      studentData = widget.initialStudentData;
      isLoadingStudent = false;
      if (studentData?['id_prodi'] != null) {
        _fetchJadwalList();
      }
    }
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final client = supabase;
    if (client != null) {
      final user = client.auth.currentUser;
      if (user != null) {
        try {
          final userId = user.id;
          final userEmail = user.email?.trim() ?? '';
          final name =
              (user.userMetadata?['full_name'] ??
                      user.userMetadata?['name'] ??
                      studentData?['Nama'] ??
                      '')
                  .toString()
                  .trim();

          List<dynamic> res = [];

          // 1. Cari berdasarkan user ID (relasi auth.users)
          res = await client
              .from('siswa')
              .select(
                '*, Kota:id_kota(Nama), prodi:id_prodi(*, fakultas:id_fakultas(*))',
              )
              .eq('id', userId)
              .limit(1);

          // 2. Fallback pencarian berdasarkan email jika id belum match
          if (res.isEmpty && userEmail.isNotEmpty) {
            res = await client
                .from('siswa')
                .select(
                  '*, Kota:id_kota(Nama), prodi:id_prodi(*, fakultas:id_fakultas(*))',
                )
                .eq('email', userEmail)
                .order('created_at', ascending: false)
                .limit(1);
          }

          // 3. Fallback pencarian berdasarkan nama jika email belum terisi
          if (res.isEmpty && name.isNotEmpty) {
            res = await client
                .from('siswa')
                .select(
                  '*, Kota:id_kota(Nama), prodi:id_prodi(*, fakultas:id_fakultas(*))',
                )
                .ilike('Nama', name)
                .order('created_at', ascending: false)
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

    // Ambil jadwal kuliah berdasarkan id_prodi milik mahasiswa
    await _fetchJadwalList();
  }

  Future<void> _fetchJadwalList() async {
    final client = supabase;
    if (client == null) return;

    final studentProdiId = studentData?['id_prodi'];
    final role = (studentData?['role'] ?? '').toString().toLowerCase().trim();
    final bool isAdmin = role == 'admin';

    if (studentProdiId == null && !isAdmin) {
      debugPrint("Student id_prodi is not available yet.");
      return;
    }

    setState(() {
      isLoadingJadwal = true;
    });

    try {
      var query = client
          .from('jadwal')
          .select('*, matkul!inner(*, dosen(*))');

      if (!isAdmin && studentProdiId != null) {
        query = query.eq('matkul.id_prodi', studentProdiId);
      }

      final data = await query.order('tanggal', ascending: true);

      if (mounted) {
        final list = List<Map<String, dynamic>>.from(data);
        setState(() {
          jadwalList = list;
        });
        _populateKegiatanEvents(list);
      }
    } catch (e) {
      debugPrint("Error fetching jadwal list: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoadingJadwal = false;
        });
      }
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
    final fullName =
        studentData?['Nama'] ??
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email?.split('@').first ??
        'Vin';
    final firstName = _getFirstName(fullName);
    final userEmail = studentData?['email'] ?? user?.email ?? '-';

    final role = (studentData?['role'] ??
            user?.userMetadata?['role'] ??
            'mahasiswa')
        .toString()
        .trim();
    final bool isAdmin = role.toLowerCase() == 'admin';
    final greetingText = isAdmin ? 'Halo tuan $firstName' : 'Halo $firstName';
    final roleSubtitle = isAdmin
        ? 'Admin'
        : (role.isNotEmpty
            ? role[0].toUpperCase() + role.substring(1).toLowerCase()
            : 'Mahasiswa');

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
                  _buildHeader(greetingText, roleSubtitle),

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
  Widget _buildHeader(String greetingText, String roleSubtitle) {
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

          // Title: Halo [Nama] & Mahasiswa / Admin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greetingText,
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
                Text(
                  roleSubtitle,
                  style: const TextStyle(
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
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
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
              color: isSelected
                  ? const Color(0xFF070B3E)
                  : const Color(0xFFD0D5DD),
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
              color: isSelected
                  ? const Color(0xFF070B3E)
                  : const Color(0xFF344054),
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
            Expanded(flex: 5, child: _buildNextClassInfoCard()),
            const SizedBox(width: 10),
            Expanded(flex: 7, child: _buildCalendarAndNotesContainer()),
          ],
        );
      },
    );
  }

  /// Info Card "Kelas Berikutnya"
  Widget _buildNextClassInfoCard() {
    final nextClass = jadwalList.isNotEmpty ? jadwalList.first : null;
    final matkul = nextClass?['matkul'] as Map<String, dynamic>?;
    final dosen = matkul?['dosen'] as Map<String, dynamic>?;

    final namaMatkul = (matkul?['nama_matkul'] ?? 'Basis Data').toString();
    final namaDosen = (dosen?['nama'] ?? 'Ibu Sevi, M.Kom.').toString();

    final tgl = _parseDate(nextClass?['tanggal']);
    final dayName = tgl != null ? _getDayName(tgl) : 'Minggu';
    final dayNum = tgl?.day ?? 23;
    final monthName = tgl != null ? _getMonthName(tgl) : 'Agustus';
    final jamMulai = _formatTime(nextClass?['jam_mulai'] ?? '09:00:00');

    final titleDate = '$dayName $dayNum $monthName,\n$jamMulai';
    final desc = nextClass != null
        ? 'Sesi kelas akan diisi oleh $namaDosen dengan matakuliah $namaMatkul'
        : 'Sesi kelas akan diisi oleh dosen ibu Sevi dengan matakuliah Basis Data';

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
          Text(
            titleDate,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF151515),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
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
        leftChevronIcon: Icon(
          Icons.chevron_left,
          size: 18,
          color: Color(0xFF070B3E),
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          size: 18,
          color: Color(0xFF070B3E),
        ),
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
        defaultTextStyle: const TextStyle(
          fontSize: 11,
          color: Color(0xFF1E293B),
        ),
        weekendTextStyle: const TextStyle(
          fontSize: 11,
          color: Color(0xFFEF4444),
        ),
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
            const Flexible(
              child: Text(
                'Catatan Kegiatan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF070B3E),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
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
                Icon(
                  Icons.event_busy_rounded,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Jadwal Kosong / Tidak ada kegiatan',
                    style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
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
              Icon(
                Icons.calendar_month_rounded,
                color: MainColor.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Jadwal Kuliah Mahasiswa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoadingJadwal)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (jadwalList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_note_rounded,
                    size: 36,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    studentData?['id_prodi'] == null
                        ? 'Program Studi belum ditentukan pada profil Anda.'
                        : 'Belum ada jadwal kuliah untuk program studi ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            ...jadwalList.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final matkul = item['matkul'] as Map<String, dynamic>?;
              final dosen = matkul?['dosen'] as Map<String, dynamic>?;

              final namaMatkul =
                  (matkul?['nama_matkul'] ?? 'Mata Kuliah').toString();
              final kodeMatkul = (matkul?['kode_matkul'] ?? '').toString();
              final sks = matkul?['sks']?.toString() ?? '0';
              final namaDosen = (dosen?['nama'] ?? 'Dosen Pengampu').toString();
              final ruangan = (item['ruangan'] ?? 'Ruang Kelas').toString();

              final tgl = _parseDate(item['tanggal']);
              final dayName = tgl != null ? _getDayName(tgl) : '';
              final tglFmt =
                  tgl != null ? '${tgl.day}/${tgl.month}/${tgl.year}' : '';
              final jamMulai = _formatTime(item['jam_mulai']);
              final jamSelesai = _formatTime(item['jam_selesai']);

              final timeStr = dayName.isNotEmpty
                  ? '$dayName, $tglFmt ($jamMulai - $jamSelesai)'
                  : '$jamMulai - $jamSelesai';
              final subjectStr = kodeMatkul.isNotEmpty
                  ? '$namaMatkul ($kodeMatkul • $sks SKS)'
                  : '$namaMatkul ($sks SKS)';

              return Column(
                children: [
                  if (idx > 0) const Divider(height: 16),
                  _buildScheduleItem(
                    timeStr,
                    subjectStr,
                    ruangan,
                    namaDosen,
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(
    String time,
    String subject,
    String room,
    String lecturer,
  ) {
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
          const Icon(Icons.check_rounded, size: 20, color: Color(0xFF1E1E1E)),
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
                    Icon(icon, size: 38, color: const Color(0xFF1E1E1E)),

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
    final nextClass = jadwalList.isNotEmpty ? jadwalList.first : null;
    final matkul = nextClass?['matkul'] as Map<String, dynamic>?;
    final dosen = matkul?['dosen'] as Map<String, dynamic>?;

    final namaMatkul = (matkul?['nama_matkul'] ?? 'Basis Data').toString();
    final sks = matkul?['sks']?.toString() ?? '3';
    final kode = (matkul?['kode_matkul'] ?? '').toString();
    final namaDosen = (dosen?['nama'] ?? 'Ibu Sevi, M.Kom.').toString();
    final ruangan = (nextClass?['ruangan'] ?? 'Lab Komputer 2').toString();

    final tgl = _parseDate(nextClass?['tanggal']);
    final dayName = tgl != null ? _getDayName(tgl) : 'Minggu';
    final dayNum = tgl?.day ?? 23;
    final monthName = tgl != null ? _getMonthName(tgl) : 'Agustus';
    final yearNum = tgl?.year ?? 2026;
    final jamMulai = _formatTime(nextClass?['jam_mulai'] ?? '09:00:00');
    final jamSelesai = _formatTime(nextClass?['jam_selesai'] ?? '11:30:00');

    final waktuStr = '$dayName, $dayNum $monthName $yearNum - $jamMulai WIB';
    final matkulStr = kode.isNotEmpty
        ? '$namaMatkul ($kode • $sks SKS)'
        : '$namaMatkul ($sks SKS)';

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
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFFC79810),
                  ),
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
            _buildDetailRow('Mata Kuliah', matkulStr),
            _buildDetailRow('Waktu', '$waktuStr (s/d $jamSelesai)'),
            _buildDetailRow('Dosen Pengampu', namaDosen),
            _buildDetailRow('Ruang / Platform', ruangan),
            _buildDetailRow(
              'Program Studi',
              studentData?['prodi']?['nama_prodi'] ??
                  studentData?['prodi']?['nama'] ??
                  (studentData?['id_prodi'] != null
                      ? 'Prodi #${studentData?['id_prodi']}'
                      : 'Reguler'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF040836),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Get.back(),
                icon: const Icon(Icons.check, size: 18),
                label: const Text(
                  'Tutup',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF2E7D32),
                  ),
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
                  Icon(
                    Icons.bookmark_outline_rounded,
                    color: Color(0xFF2E7D32),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sistem Manajemen Basis Data Modern',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Jatuh tempo: 28 Agustus 2026',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Get.back(),
                child: const Text(
                  'Tutup',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF8E24AA),
                  ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Get.back(),
                child: const Text(
                  'Tutup',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
                  child: const Icon(
                    Icons.assignment_turned_in_outlined,
                    color: Color(0xFF7E7514),
                  ),
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
            const Text(
              'Daftar Mata Kuliah:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Get.back(),
                child: const Text(
                  'Tutup',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
          Text(
            sks,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
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
                  child: const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF3949AB),
                  ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Get.back(),
                child: const Text(
                  'Tutup',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
    final fullName =
        studentData?['Nama'] ??
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
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              _buildDetailRow('NIS', studentData?['Nis'] ?? '-'),
              _buildDetailRow(
                'Tanggal Lahir',
                studentData?['TanggalLahir'] ?? '-',
              ),
              _buildDetailRow(
                'Jenis Kelamin',
                studentData?['JenisKelamin'] == true
                    ? 'Laki-laki'
                    : (studentData?['JenisKelamin'] == false
                          ? 'Perempuan'
                          : '-'),
              ),
              _buildDetailRow(
                'Kota Asal',
                studentData?['Kota']?['Nama'] ??
                    (studentData?['id_kota'] != null
                        ? 'Kota #${studentData?['id_kota']}'
                        : '-'),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                    _logout();
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text(
                    'Keluar / Logout',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// App Navigation Drawer
  Widget _buildAppDrawer(String fullName, String userEmail) {
    final role = (studentData?['role'] ??
            supabase?.auth.currentUser?.userMetadata?['role'] ??
            '')
        .toString()
        .toLowerCase()
        .trim();
    final bool isAdmin = role == 'admin';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    decoration: const BoxDecoration(color: Color(0xFF040836)),
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
                ],
              ),
            ),
            if (isAdmin) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFF040836),
                ),
                title: const Text(
                  'Kelola Jadwal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF040836),
                  ),
                ),
                subtitle: const Text(
                  'Panel Admin',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAdminKelolaJadwalModal();
                },
              ),
            ],
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text(
                'Keluar / Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAdminKelolaJadwalModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdminKelolaJadwalSheet(
        onJadwalChanged: () {
          _fetchJadwalList();
        },
      ),
    );
  }
}

class _AdminKelolaJadwalSheet extends StatefulWidget {
  final VoidCallback onJadwalChanged;

  const _AdminKelolaJadwalSheet({required this.onJadwalChanged});

  @override
  State<_AdminKelolaJadwalSheet> createState() =>
      _AdminKelolaJadwalSheetState();
}

class _AdminKelolaJadwalSheetState extends State<_AdminKelolaJadwalSheet> {
  List<Map<String, dynamic>> _list = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchJadwalList();
  }

  Future<void> _fetchJadwalList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final data = await client
          .from('jadwal')
          .select('*, matkul(*, dosen(*))')
          .order('tanggal', ascending: true);

      if (mounted) {
        setState(() {
          _list = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat jadwal: $e';
        });
      }
    }
  }

  String _formatTime(dynamic time) {
    if (time == null) return '--:--';
    final str = time.toString();
    final parts = str.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return str;
  }

  String _formatDateDisplay(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr.toString());
      const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final dayName = days[dt.weekday - 1];
      final monthName = months[dt.month - 1];
      return '$dayName, ${dt.day} $monthName ${dt.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }

  void _openFormDialog({Map<String, dynamic>? jadwalToEdit}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AdminJadwalFormDialog(
        jadwalToEdit: jadwalToEdit,
        onSuccess: () {
          _fetchJadwalList();
          widget.onJadwalChanged();
        },
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    final matkul = item['matkul'] as Map<String, dynamic>?;
    final namaMatkul = matkul?['nama_matkul'] ?? 'Mata Kuliah';
    final tglStr = _formatDateDisplay(item['tanggal']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('Hapus Jadwal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus jadwal untuk mata kuliah "$namaMatkul" pada tanggal $tglStr?\n\nData yang dihapus tidak dapat dipulihkan.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteJadwal(item['id']);
            },
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteJadwal(dynamic id) async {
    try {
      final client = Supabase.instance.client;
      await client.from('jadwal').delete().eq('id', id);

      await _fetchJadwalList();
      widget.onJadwalChanged();

      Get.snackbar(
        'Berhasil Dihapus',
        'Jadwal perkuliahan berhasil dihapus.',
        backgroundColor: const Color(0xFFE8F5E9),
        colorText: const Color(0xFF2E7D32),
        icon: const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Gagal Menghapus',
        e.toString(),
        backgroundColor: const Color(0xFFFFEBEE),
        colorText: const Color(0xFFC62828),
        icon: const Icon(Icons.error_outline, color: Color(0xFFC62828)),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF040836).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Color(0xFF040836),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelola Jadwal Kuliah',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Panel Manajemen CRUD Admin',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Total ${_list.length} Jadwal',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF040836),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _openFormDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Tambah Jadwal',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 2.5),
                        SizedBox(height: 12),
                        Text(
                          'Memuat jadwal kuliah...',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _fetchJadwalList,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _list.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.event_busy_rounded, size: 56, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Belum Ada Jadwal Kuliah',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Tekan tombol "Tambah Jadwal" di atas untuk menambahkan data baru.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchJadwalList,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _list.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = _list[index];
                                final matkul = item['matkul'] as Map<String, dynamic>?;
                                final dosen = matkul?['dosen'] as Map<String, dynamic>?;
                                final namaMatkul = matkul?['nama_matkul'] ?? 'Mata Kuliah';
                                final kodeMatkul = matkul?['kode_matkul'] ?? '';
                                final sks = matkul?['sks']?.toString() ?? '0';
                                final namaDosen = dosen?['nama'] ?? '';
                                final ruangan = item['ruangan'] ?? '-';
                                final jamMulai = _formatTime(item['jam_mulai']);
                                final jamSelesai = _formatTime(item['jam_selesai']);
                                final tglStr = _formatDateDisplay(item['tanggal']);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  namaMatkul,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  kodeMatkul.isNotEmpty ? '$kodeMatkul • $sks SKS' : '$sks SKS',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.blueGrey.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20),
                                            color: const Color(0xFF2C5EAD),
                                            tooltip: 'Edit Jadwal',
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(6),
                                            onPressed: () => _openFormDialog(jadwalToEdit: item),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                            color: Colors.redAccent,
                                            tooltip: 'Hapus Jadwal',
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(6),
                                            onPressed: () => _confirmDelete(item),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 16),
                                      Wrap(
                                        spacing: 14,
                                        runSpacing: 6,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF040836)),
                                              const SizedBox(width: 5),
                                              Text(tglStr, style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155))),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF040836)),
                                              const SizedBox(width: 5),
                                              Text('$jamMulai - $jamSelesai WIB', style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155))),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.meeting_room_outlined, size: 14, color: Color(0xFF040836)),
                                              const SizedBox(width: 5),
                                              Text(ruangan, style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155))),
                                            ],
                                          ),
                                          if (namaDosen.isNotEmpty)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF040836)),
                                                const SizedBox(width: 5),
                                                Text(namaDosen, style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155))),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _AdminJadwalFormDialog extends StatefulWidget {
  final Map<String, dynamic>? jadwalToEdit;
  final VoidCallback onSuccess;

  const _AdminJadwalFormDialog({
    this.jadwalToEdit,
    required this.onSuccess,
  });

  @override
  State<_AdminJadwalFormDialog> createState() => _AdminJadwalFormDialogState();
}

class _AdminJadwalFormDialogState extends State<_AdminJadwalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ruanganController = TextEditingController();

  List<Map<String, dynamic>> _matkulList = [];
  bool _isLoadingMatkul = true;
  int? _selectedMatkulId;

  DateTime? _selectedDate;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isEditing => widget.jadwalToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final edit = widget.jadwalToEdit!;
      _selectedMatkulId = edit['id_matkul'] as int?;
      _selectedDate = _parseDate(edit['tanggal']);
      _jamMulai = _parseTimeOfDay(edit['jam_mulai']);
      _jamSelesai = _parseTimeOfDay(edit['jam_selesai']);
      _ruanganController.text = (edit['ruangan'] ?? '').toString();
    } else {
      _selectedDate = DateTime.now();
      _jamMulai = const TimeOfDay(hour: 8, minute: 0);
      _jamSelesai = const TimeOfDay(hour: 10, minute: 30);
    }
    _fetchMatkulList();
  }

  @override
  void dispose() {
    _ruanganController.dispose();
    super.dispose();
  }

  DateTime _parseDate(dynamic dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      return DateTime.parse(dateStr.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  TimeOfDay _parseTimeOfDay(dynamic timeStr) {
    if (timeStr == null) return const TimeOfDay(hour: 8, minute: 0);
    final str = timeStr.toString();
    final parts = str.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  String _displayDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _displayTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m WIB';
  }

  Future<void> _fetchMatkulList() async {
    try {
      final client = Supabase.instance.client;
      final data = await client
          .from('matkul')
          .select('id, nama_matkul, kode_matkul, sks')
          .order('nama_matkul', ascending: true);

      if (mounted) {
        final list = List<Map<String, dynamic>>.from(data);
        setState(() {
          _matkulList = list;
          _isLoadingMatkul = false;
          if (_selectedMatkulId == null && list.isNotEmpty) {
            _selectedMatkulId = list.first['id'] as int?;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMatkul = false;
          _errorMessage = 'Gagal memuat mata kuliah: $e';
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF040836),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickJamMulai() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _jamMulai ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF040836),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _jamMulai = picked;
      });
    }
  }

  Future<void> _pickJamSelesai() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _jamSelesai ?? const TimeOfDay(hour: 10, minute: 30),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF040836),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _jamSelesai = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedMatkulId == null) {
      Get.snackbar(
        'Peringatan',
        'Silakan pilih mata kuliah terlebih dahulu.',
        backgroundColor: Colors.amber.shade100,
        colorText: Colors.amber.shade900,
      );
      return;
    }
    if (_selectedDate == null) {
      Get.snackbar(
        'Peringatan',
        'Silakan pilih tanggal jadwal perkuliahan.',
        backgroundColor: Colors.amber.shade100,
        colorText: Colors.amber.shade900,
      );
      return;
    }
    if (_jamMulai == null || _jamSelesai == null) {
      Get.snackbar(
        'Peringatan',
        'Silakan tentukan jam mulai dan jam selesai.',
        backgroundColor: Colors.amber.shade100,
        colorText: Colors.amber.shade900,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final payload = {
        'id_matkul': _selectedMatkulId,
        'tanggal': _formatDate(_selectedDate!),
        'jam_mulai': _formatTimeOfDay(_jamMulai!),
        'jam_selesai': _formatTimeOfDay(_jamSelesai!),
        'ruangan': _ruanganController.text.trim(),
      };

      if (isEditing) {
        await client
            .from('jadwal')
            .update(payload)
            .eq('id', widget.jadwalToEdit!['id']);

        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess();
          Get.snackbar(
            'Berhasil Diperbarui',
            'Jadwal perkuliahan berhasil diperbarui.',
            backgroundColor: const Color(0xFFE8F5E9),
            colorText: const Color(0xFF2E7D32),
            icon: const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        await client.from('jadwal').insert(payload);

        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess();
          Get.snackbar(
            'Berhasil Disimpan',
            'Jadwal perkuliahan baru berhasil ditambahkan.',
            backgroundColor: const Color(0xFFE8F5E9),
            colorText: const Color(0xFF2E7D32),
            icon: const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Gagal menyimpan: $e';
        });
        Get.snackbar(
          'Gagal Menyimpan',
          e.toString(),
          backgroundColor: const Color(0xFFFFEBEE),
          colorText: const Color(0xFFC62828),
          icon: const Icon(Icons.error_outline, color: Color(0xFFC62828)),
          snackPosition: SnackPosition.TOP,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF040836).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                        color: const Color(0xFF040836),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Jadwal Kuliah' : 'Tambah Jadwal Baru',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 16),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 1. Pilih Mata Kuliah
                const Text(
                  'Mata Kuliah',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                if (_isLoadingMatkul)
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Memuat daftar mata kuliah...', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  )
                else if (_matkulList.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Belum ada data mata kuliah di database.',
                        style: TextStyle(color: Colors.black87, fontSize: 13)),
                  )
                else
                  DropdownButtonFormField<int>(
                    initialValue: _selectedMatkulId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.menu_book_rounded, color: Color(0xFF040836)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF040836), width: 1.5),
                      ),
                    ),
                    items: _matkulList.map((item) {
                      final nama = item['nama_matkul'] ?? 'Mata Kuliah';
                      final kode = item['kode_matkul'] != null ? ' (${item['kode_matkul']})' : '';
                      final sks = item['sks'] != null ? ' - ${item['sks']} SKS' : '';
                      return DropdownMenuItem<int>(
                        value: item['id'] as int,
                        child: Text(
                          '$nama$kode$sks',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedMatkulId = val;
                      });
                    },
                  ),

                const SizedBox(height: 14),

                // 2. Tanggal Perkuliahan
                const Text(
                  'Tanggal Perkuliahan',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Color(0xFF040836), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate != null
                              ? _displayDate(_selectedDate!)
                              : 'Pilih Tanggal',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, color: Colors.black54),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Jam Mulai & Jam Selesai
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jam Mulai',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickJamMulai,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, color: Color(0xFF040836), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _jamMulai != null ? _displayTimeOfDay(_jamMulai!) : '--:--',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jam Selesai',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickJamSelesai,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_filled_rounded, color: Color(0xFF040836), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _jamSelesai != null ? _displayTimeOfDay(_jamSelesai!) : '--:--',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 4. Ruangan Kelas
                const Text(
                  'Ruangan Kelas',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _ruanganController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Lab Komputer 1 / Ruang 302',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
                    prefixIcon: const Icon(Icons.meeting_room_outlined, color: Color(0xFF040836)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF040836), width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Ruangan wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 22),

                // 5. Actions: Batal & Simpan / Perbarui
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF040836),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isSubmitting ? null : _submitForm,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEditing ? 'Perbarui Jadwal' : 'Simpan Jadwal',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

