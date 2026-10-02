import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:belajar/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Google Sign-In & Student Flow Integration Test', () {
    testWidgets('Verify Login Screen displays UNNES branding and Google Sign-In button', (tester) async {
      await tester.pumpWidget(const MyApp());
      // Wait for SplashScreen transition to LoginScreen
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check UNNES Branding & Login components
      expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
      expect(find.byKey(const Key('input_email')), findsOneWidget);
      expect(find.byKey(const Key('input_password')), findsOneWidget);
      expect(find.byKey(const Key('btn_login')), findsOneWidget);
      expect(find.text('Masuk dengan Google'), findsOneWidget);
    });
  });
}
