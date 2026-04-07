import 'package:app/src/core/config/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupabaseConfig.isConfigured', () {
    test('returns false when URL or anon key is empty', () {
      expect(
        const SupabaseConfig(url: '', anonKey: 'anon').isConfigured,
        isFalse,
      );
      expect(
        const SupabaseConfig(url: 'https://proj.supabase.co', anonKey: '')
            .isConfigured,
        isFalse,
      );
    });

    test('returns false for placeholder values', () {
      expect(
        const SupabaseConfig(
          url: 'YOUR_SUPABASE_URL',
          anonKey: 'anon-key',
        ).isConfigured,
        isFalse,
      );
      expect(
        const SupabaseConfig(
          url: 'https://proj.supabase.co',
          anonKey: 'YOUR_SUPABASE_ANON_KEY',
        ).isConfigured,
        isFalse,
      );
    });

    test('returns false for invalid URL forms', () {
      expect(
        const SupabaseConfig(
          url: 'not-a-url',
          anonKey: 'anon-key',
        ).isConfigured,
        isFalse,
      );
      expect(
        const SupabaseConfig(
          url: 'ftp://proj.supabase.co',
          anonKey: 'anon-key',
        ).isConfigured,
        isFalse,
      );
      expect(
        const SupabaseConfig(url: 'https://', anonKey: 'anon-key').isConfigured,
        isFalse,
      );
    });

    test('returns true for valid HTTP(S) URL with host and anon key', () {
      expect(
        const SupabaseConfig(
          url: 'https://project-ref.supabase.co',
          anonKey: 'anon-key',
        ).isConfigured,
        isTrue,
      );
      expect(
        const SupabaseConfig(
          url: 'http://127.0.0.1:54321',
          anonKey: 'anon-key',
        ).isConfigured,
        isTrue,
      );
    });
  });
}
