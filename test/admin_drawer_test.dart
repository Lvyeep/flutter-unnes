import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:belajar/dashboard.dart';

void main() {
  group('Admin Drawer Menu & Greeting Tests', () {
    testWidgets('Non-admin user has standard greeting and does NOT see Kelola Jadwal in drawer', (tester) async {
      final nonAdminData = {
        'id': 'user-1',
        'Nama': 'Budi Santoso',
        'email': 'budi@example.com',
        'role': 'mahasiswa',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(initialStudentData: nonAdminData),
        ),
      );
      await tester.pump();

      // Check dynamic greeting & subtitle
      expect(find.text('Halo Budi'), findsOneWidget);
      expect(find.text('Mahasiswa'), findsOneWidget);

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Admin menu should NOT exist
      expect(find.text('Kelola Jadwal'), findsNothing);
      expect(find.text('Panel Admin'), findsNothing);
      expect(find.byIcon(Icons.admin_panel_settings), findsNothing);

      // Logout should exist
      expect(find.text('Keluar / Logout'), findsOneWidget);
    });

    testWidgets('Admin user sees "Halo tuan [nama]", "Admin" subtitle, and "Kelola Jadwal" in drawer', (tester) async {
      final adminData = {
        'id': 'user-admin',
        'Nama': 'Admin Ganteng',
        'email': 'admin@example.com',
        'role': 'admin',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(initialStudentData: adminData),
        ),
      );
      await tester.pump();

      // Check dynamic greeting & subtitle
      expect(find.text('Halo tuan Admin'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Admin menu MUST exist
      expect(find.text('Kelola Jadwal'), findsOneWidget);
      expect(find.text('Panel Admin'), findsOneWidget);
      expect(find.byIcon(Icons.admin_panel_settings), findsOneWidget);

      // Logout also exists
      expect(find.text('Keluar / Logout'), findsOneWidget);
    });

    testWidgets('Tapping Kelola Jadwal opens management sheet with Tambah Jadwal button and dialog form', (tester) async {
      final adminData = {
        'id': 'user-admin',
        'Nama': 'Admin Ganteng',
        'email': 'admin@example.com',
        'role': 'admin',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(initialStudentData: adminData),
        ),
      );
      await tester.pump();

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Tap on Kelola Jadwal
      await tester.tap(find.text('Kelola Jadwal'));
      await tester.pumpAndSettle();

      // Management BottomSheet should now be visible
      expect(find.text('Kelola Jadwal Kuliah'), findsOneWidget);
      expect(find.text('Tambah Jadwal'), findsOneWidget);

      // Tap Tambah Jadwal button to open form dialog
      await tester.tap(find.text('Tambah Jadwal'));
      await tester.pumpAndSettle();

      // Form dialog should be visible
      expect(find.text('Tambah Jadwal Baru'), findsOneWidget);
      expect(find.text('Mata Kuliah'), findsOneWidget);
      expect(find.text('Tanggal Perkuliahan'), findsOneWidget);
      expect(find.text('Jam Mulai'), findsOneWidget);
      expect(find.text('Jam Selesai'), findsOneWidget);
      expect(find.text('Ruangan Kelas'), findsOneWidget);
      expect(find.text('Simpan Jadwal'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });
  });
}
