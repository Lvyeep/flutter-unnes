import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // If .env file cannot be loaded directly as an asset, use default values
      debugPrint('Notice: .env loaded with fallback or error: $e');
    }
  }

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL']?.trim() ??
      'https://cjhyequzugwalzowlvhn.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY']?.trim() ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqaHllcXV6dWd3YWx6b3dsdmhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2MDA3MzQsImV4cCI6MjEwMDE3NjczNH0.r57wjmK6yAlpMxn3gf5l9n5QGsN3U9INWCrom8x8rus';

  static String get webClientId =>
      dotenv.env['WEB_CLIENT']?.trim() ??
      dotenv.env['WEB_CLIENT_ID']?.trim() ??
      '489552158346-salgof01n0tbk9pj0v1ge8iov5ddnr6n.apps.googleusercontent.com';

  static String get androidClientId =>
      dotenv.env['ANDROID_CLIENT']?.trim() ??
      dotenv.env['ANDROID_CLIENT_ID']?.trim() ??
      '489552158346-c4585i46gruev2o6vfqlbfkr28bjdjom.apps.googleusercontent.com';

  static String get iosClientId =>
      dotenv.env['IOS_CLIENT_ID']?.trim() ??
      dotenv.env['IOS_CLIENT']?.trim() ??
      dotenv.env['WEB_CLIENT']?.trim() ??
      '489552158346-salgof01n0tbk9pj0v1ge8iov5ddnr6n.apps.googleusercontent.com';
}
