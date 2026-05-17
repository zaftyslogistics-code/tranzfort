import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../logger/app_logger.dart';

/// Supabase configuration loader.
/// Reads from compile-time environment variables via --dart-define (production builds).
/// Falls back to .env file for local development (IDE runs).
/// Never hardcode keys in code.
class SupabaseConfig {
  final String url;
  final String anonKey;
  final String googleWebClientId;

  const SupabaseConfig({
    required this.url,
    required this.anonKey,
    required this.googleWebClientId,
  });

  bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      !url.contains('YOUR_SUPABASE_URL') &&
      Uri.tryParse(url)?.hasScheme == true;

  static SupabaseConfig fromEnvironment() {
    // Try to read from --dart-define (production builds)
    final urlFromDefine = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    final anonKeyFromDefine = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    final googleClientIdFromDefine = const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

    AppLogger.debug('SupabaseConfig: Checking --dart-define values', scope: 'supabase_config');
    AppLogger.debug('SUPABASE_URL from --dart-define: ${urlFromDefine.isNotEmpty ? "SET" : "EMPTY"}', scope: 'supabase_config');
    AppLogger.debug('SUPABASE_ANON_KEY from --dart-define: ${anonKeyFromDefine.isNotEmpty ? "SET" : "EMPTY"}', scope: 'supabase_config');

    // If --dart-define values are present, use them (production build)
    if (urlFromDefine.isNotEmpty && anonKeyFromDefine.isNotEmpty) {
      AppLogger.info('Using --dart-define for Supabase configuration', scope: 'supabase_config');
      return SupabaseConfig(
        url: urlFromDefine,
        anonKey: anonKeyFromDefine,
        googleWebClientId: googleClientIdFromDefine,
      );
    }

    // Fallback: Read from .env file (local IDE development)
    AppLogger.info('--dart-define not provided, falling back to .env file', scope: 'supabase_config');
    try {
      dotenv.load(fileName: '.env');
      final url = dotenv.env['SUPABASE_URL'] ?? '';
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      final googleClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
      
      AppLogger.debug('SUPABASE_URL from .env: ${url.isNotEmpty ? "SET" : "EMPTY"}', scope: 'supabase_config');
      AppLogger.debug('SUPABASE_ANON_KEY from .env: ${anonKey.isNotEmpty ? "SET" : "EMPTY"}', scope: 'supabase_config');
      
      if (url.isEmpty || anonKey.isEmpty) {
        AppLogger.warning('.env file loaded but SUPABASE_URL or SUPABASE_ANON_KEY is empty', scope: 'supabase_config');
      } else {
        AppLogger.info('Using .env file for Supabase configuration', scope: 'supabase_config');
      }
      
      return SupabaseConfig(
        url: url,
        anonKey: anonKey,
        googleWebClientId: googleClientId,
      );
    } catch (e) {
      AppLogger.warning('Error reading .env file', scope: 'supabase_config', error: e);
      return const SupabaseConfig(
        url: '',
        anonKey: '',
        googleWebClientId: '',
      );
    }
  }
}
