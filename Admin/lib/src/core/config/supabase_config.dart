import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseConfiguredProvider = Provider<bool>((ref) => false);

class SupabaseConfig {
  final String url;
  final String anonKey;

  const SupabaseConfig({required this.url, required this.anonKey});

  bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  factory SupabaseConfig.fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    return const SupabaseConfig(url: url, anonKey: anonKey);
  }
}
