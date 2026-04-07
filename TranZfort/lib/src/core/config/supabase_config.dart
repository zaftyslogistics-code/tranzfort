import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration loader.
/// Reads from .env file. Never hardcode keys in code.
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
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      googleWebClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '',
    );
  }
}
