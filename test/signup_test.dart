import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:belajar/signup.dart';

void main() {
  testWidgets('SignupScreen renders all required form fields including dynamic dropdowns', (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: SignupScreen(),
      ),
    );

    // Verify key titles & field labels exist
    expect(find.text('Registrasi Akun Mahasiswa'), findsOneWidget);
    expect(find.text('Identitas Diri & Akun'), findsOneWidget);
    expect(find.text('Data Akademik (Fakultas, Prodi & Semester)'), findsOneWidget);
    expect(find.text('Data Diri & Alamat'), findsOneWidget);

    // Verify input fields & dropdowns
    expect(find.byKey(const Key('input_nama')), findsOneWidget);
    expect(find.byKey(const Key('input_email')), findsOneWidget);
    expect(find.byKey(const Key('input_password')), findsOneWidget);
    expect(find.byKey(const Key('input_nis')), findsOneWidget);

    // Verify dropdown keys
    expect(find.byKey(const Key('dropdown_fakultas')), findsOneWidget);
    expect(find.byKey(const Key('dropdown_semester')), findsOneWidget);
    expect(find.text('Pilih Fakultas terlebih dahulu'), findsOneWidget); // Prodi placeholder before fakultas selected

    // Verify submit button
    expect(find.byKey(const Key('btn_submit_register')), findsOneWidget);
  });
}
