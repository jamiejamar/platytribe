import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
class Env {
  static const _urlDefine = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const _keyDefine = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const _siteDefine = String.fromEnvironment('SITE_URL', defaultValue: '');
  static const _envDefine  = String.fromEnvironment('ENV', defaultValue: '');
  static Future<void> load() async {
    if (_urlDefine.isEmpty || _keyDefine.isEmpty) {
      await dotenv.load(fileName: kReleaseMode ? '.env.production' : '.env.development');
    }
  }
  static String get supabaseUrl => _urlDefine.isNotEmpty ? _urlDefine : (dotenv.env['SUPABASE_URL'] ?? '');
  static String get supabaseAnonKey => _keyDefine.isNotEmpty ? _keyDefine : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');
  static String get siteUrl => _siteDefine.isNotEmpty ? _siteDefine : (dotenv.env['SITE_URL'] ?? '');
  static String get envName => _envDefine.isNotEmpty ? _envDefine : (dotenv.env['ENV'] ?? 'dev');
}
