import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseConfiguredProvider = Provider<bool>((ref) => false);

class SupabaseConfig {
  final String url;
  final String anonKey;

  const SupabaseConfig({required this.url, required this.anonKey});

  bool get isConfigured {
    if (url.isEmpty || anonKey.isEmpty) return false;

    final normalizedUrl = url.trim();
    final normalizedKey = anonKey.trim();

    if (normalizedUrl.contains('YOUR_SUPABASE_URL')) return false;
    if (normalizedKey.contains('YOUR_SUPABASE_ANON_KEY')) return false;

    final parsed = Uri.tryParse(normalizedUrl);
    return parsed != null &&
        (parsed.scheme == 'https' || parsed.scheme == 'http') &&
        parsed.host.isNotEmpty;
  }

  factory SupabaseConfig.fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    return const SupabaseConfig(url: url, anonKey: anonKey);
  }
}
