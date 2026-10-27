import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:belajar/dashboard.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('Dashboard MVP Feature Tests', () {
    testWidgets('Kelas Terdekat Anda displays friendly message when empty', (tester) async {
      final mockData = {
        'id': 'user-1',
        'Nama': 'Siti Aminah',
        'email': 'siti@example.com',
        'role': 'mahasiswa',
      };

      await tester.pumpWidget(
        GetMaterialApp(
          home: DashboardScreen(
            initialStudentData: mockData,
            initialUpcomingClass: null,
          ),
        ),
      );
      await tester.pump();

      // Check card title
      expect(find.text('Kelas Terdekat Anda'), findsOneWidget);

      // Check empty state text
      expect(
        find.text('Tidak ada jadwal kelas lanjutan untuk hari ini. Selamat beristirahat!'),
        findsOneWidget,
      );
    });

    testWidgets('Kelas Terdekat Anda displays class name, time, and room when class exists', (tester) async {
      final mockData = {
        'id': 'user-1',
        'Nama': 'Siti Aminah',
        'email': 'siti@example.com',
        'role': 'mahasiswa',
      };

      final mockUpcomingClass = {
        'id': 101,
        'tanggal': '2026-10-27',
        'jam_mulai': '10:00:00',
        'jam_selesai': '12:30:00',
        'ruangan': 'Lab Komputer 3',
        'matkul': {
          'id': 1,
          'nama_matkul': 'Pemrograman Lanjut',
          'kode_matkul': 'IF302',
          'sks': 3,
        },
      };

      await tester.pumpWidget(
        GetMaterialApp(
          home: DashboardScreen(
            initialStudentData: mockData,
            initialUpcomingClass: mockUpcomingClass,
          ),
        ),
      );
      await tester.pump();

      // Check card title and badge
      expect(find.text('Kelas Terdekat Anda'), findsOneWidget);
      expect(find.text('Hari Ini'), findsOneWidget);

      // Check matkul title with code
      expect(find.text('Pemrograman Lanjut (IF302)'), findsOneWidget);

      // Check time formatted
      expect(find.text('10:00 - 12:30 WIB'), findsOneWidget);

      // Check room
      expect(find.text('Lab Komputer 3'), findsOneWidget);
    });

    for (final feature in [
      'Presensi',
      'Perpustakaan',
      'Status UKT',
      'Kartu Rencana Studi',
      'KHS & Nilai',
    ]) {
      testWidgets('Tapping $feature in Drawer triggers orange snackbar', (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockData = {
          'id': 'user-1',
          'Nama': 'Budi Santoso',
          'email': 'budi@example.com',
          'role': 'mahasiswa',
        };

        await tester.pumpWidget(
          GetMaterialApp(
            home: DashboardScreen(initialStudentData: mockData),
          ),
        );
        await tester.pumpAndSettle();

        final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        final tileFinder = find.widgetWithText(ListTile, feature);
        expect(tileFinder, findsOneWidget);

        await tester.tap(tileFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text('Fitur $feature masih dalam tahap pengembangan.'),
          findsOneWidget,
        );

        // Advance timer so snackbar ticker finishes and doesn't leak
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
      });
    }

    testWidgets('Admin drawer button Kelola Jadwal is shown only for admin role', (tester) async {
      final adminData = {
        'id': 'user-admin',
        'Nama': 'Admin Prodi',
        'email': 'admin@example.com',
        'role': 'admin',
      };

      await tester.pumpWidget(
        GetMaterialApp(
          home: DashboardScreen(initialStudentData: adminData),
        ),
      );
      await tester.pump();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Kelola Jadwal'), findsOneWidget);
      expect(find.text('Panel Admin'), findsOneWidget);
    });
  });
}

