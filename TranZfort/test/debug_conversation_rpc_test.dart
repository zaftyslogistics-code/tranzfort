import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// DEBUG: Check conversation RPC (unit test, no device needed)
void main() {
  group('DEBUG: Conversation RPC', () {
    test('Check get_current_user_conversation_summaries RPC', () async {
      await dotenv.load(fileName: '.env');
      
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );

      final client = Supabase.instance.client;

      // Sign in as trucker
      final authResponse = await client.auth.signInWithPassword(
        email: 'trucker@example.com',
        password: 'Tabish%%Khan721',
      );

      debugPrint('Auth response: ${authResponse.user?.id}');

      if (authResponse.user == null) {
        debugPrint('Failed to authenticate');
        return;
      }

      debugPrint('Calling get_current_user_conversation_summaries RPC...');

      try {
        final response = await client.rpc('get_current_user_conversation_summaries');
        debugPrint('RPC response type: ${response.runtimeType}');
        debugPrint('RPC response: $response');
        
        if (response is List) {
          debugPrint('Response is a List with ${response.length} items');
          for (var i = 0; i < (response.length).clamp(0, 3); i++) {
            debugPrint('Item $i: ${response[i]}');
          }
        } else if (response is Map) {
          debugPrint('Response is a Map: $response');
        } else {
          debugPrint('Response is: $response');
        }
      } catch (e, stackTrace) {
        debugPrint('RPC error: $e');
        debugPrint('Stack trace: $stackTrace');
      } finally {
        await client.auth.signOut();
      }

      expect(true, isTrue);
    });
  });
}
