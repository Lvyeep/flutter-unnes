import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:belajar/dashboard.dart';

void main() {
  group('Admin Drawer Menu Tests', () {
    testWidgets('Non-admin user does NOT see Admin Panel menu in drawer', (tester) async {
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

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Admin menu should NOT exist
      expect(find.text('Panel Admin'), findsNothing);
      expect(find.byIcon(Icons.admin_panel_settings), findsNothing);

      // Logout should exist
      expect(find.text('Keluar / Logout'), findsOneWidget);
    });

    testWidgets('Admin user sees Admin Panel menu in drawer above logout', (tester) async {
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

      // Admin menu MUST exist
      expect(find.text('Panel Admin'), findsOneWidget);
      expect(find.byIcon(Icons.admin_panel_settings), findsOneWidget);

      // Logout also exists
      expect(find.text('Keluar / Logout'), findsOneWidget);
    });

    testWidgets('Tapping Admin Panel menu opens schedule creation Modal Bottom Sheet', (tester) async {
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

      // Tap on Admin Panel
      await tester.tap(find.text('Panel Admin'));
      await tester.pumpAndSettle();

      // Form elements should now be visible in the bottom sheet
      expect(find.text('Kelola Jadwal Kuliah'), findsOneWidget);
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
