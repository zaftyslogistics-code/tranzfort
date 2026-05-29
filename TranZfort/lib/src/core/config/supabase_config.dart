import '../logger/app_logger.dart';

/// Supabase configuration loader.
/// Reads from compile-time environment variables via --dart-define (production builds).
/// Required values: SUPABASE_URL, SUPABASE_ANON_KEY.
/// Optional values: GOOGLE_WEB_CLIENT_ID.
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
    // Read from --dart-define (production builds)
    final urlFromDefine = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    final anonKeyFromDefine = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    final googleClientIdFromDefine = const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

    AppLogger.debug('SupabaseConfig: Checking --dart-define values', scope: 'supabase_config');
    AppLogger.debug('SUPABASE_URL from --dart-define: ${urlFromDefine.isNotEmpty ? "SET" : "EMPTY"}', scope: 'supabase_config');
    AppLogger.debug('SUPABASE_ANON_KEY from --dart-define: ${anonKeyFromDefine.isNotEmpty ? "SET" : "EMPTY"}', scope: 'supabase_config');

    // Fail fast if required --dart-define values are missing
    if (urlFromDefine.isEmpty || anonKeyFromDefine.isEmpty) {
      AppLogger.error(
        'Required --dart-define values are missing: SUPABASE_URL and SUPABASE_ANON_KEY must be provided at build time',
        scope: 'supabase_config',
      );
      return const SupabaseConfig(
        url: '',
        anonKey: '',
        googleWebClientId: '',
      );
    }

    AppLogger.info('Using --dart-define for Supabase configuration', scope: 'supabase_config');
    return SupabaseConfig(
      url: urlFromDefine,
      anonKey: anonKeyFromDefine,
      googleWebClientId: googleClientIdFromDefine,
    );
  }
}
