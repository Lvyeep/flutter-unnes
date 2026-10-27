import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:belajar/color.dart';
import 'package:belajar/dashboard.dart';

void main() {
  group('App Unit Tests', () {
    test('Color palette validation matches brand specification', () {
      expect(MainColor.primaryColor, const Color(0xFF2C5EAD));
      expect(MainColor.secondaryColor, const Color(0xFF1591DC));
      expect(MainColor.thirdColor, const Color(0xFF4BB8FA));
      expect(MainColor.fourthColor, const Color(0xFFC4E2F5));
    });

    testWidgets('Header branding widget test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard Siswa'),
              backgroundColor: MainColor.primaryColor,
            ),
            body: Center(
              child: Text(
                'SISTEM SISWA UNNES',
                style: TextStyle(color: MainColor.primaryColor),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Dashboard Siswa'), findsOneWidget);
      expect(find.text('SISTEM SISWA UNNES'), findsOneWidget);
    });

    testWidgets('DashboardScreen renders profile data correctly', (WidgetTester tester) async {
      final mockStudentData = {
        'id': 99,
        'Nama': 'Ahmad Fauzi',
        'Nis': '2026001',
        'TanggalLahir': '2005-05-12',
        'JenisKelamin': true,
        'Alamat': 'Jl. Sekaran No. 1, Gunungpati, Semarang',
        'Nortu': '081234567890',
        'Kota': {'Nama': 'Semarang'},
      };

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(initialStudentData: mockStudentData),
        ),
      );

      await tester.pump();

      // Open drawer to check student full name in drawer header
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Ahmad Fauzi'), findsOneWidget);
      expect(find.text('Keluar / Logout'), findsOneWidget);
    });
  });
}
