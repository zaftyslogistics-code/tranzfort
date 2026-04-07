import 'package:admin/src/core/config/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Admin SupabaseConfig.isConfigured', () {
    test('returns false when URL is empty', () {
      const config = SupabaseConfig(url: '', anonKey: 'anon');
      expect(config.isConfigured, isFalse);
    });

    test('returns false when anon key is empty', () {
      const config = SupabaseConfig(url: 'https://project.supabase.co', anonKey: '');
      expect(config.isConfigured, isFalse);
    });

    test('returns true when both URL and anon key are present', () {
      const config = SupabaseConfig(
        url: 'https://project.supabase.co',
        anonKey: 'anon',
      );
      expect(config.isConfigured, isTrue);
    });
  });
}
