/// Supabase configuration loader.
/// Reads from compile-time environment variables via --dart-define.
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

  factory SupabaseConfig.fromEnvironment() {
    return SupabaseConfig(
      url: const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
      googleWebClientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: ''),
    );
  }
}
