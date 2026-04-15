import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// DEBUG: Check conversation RPC
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> initSupabase() async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  group('DEBUG: Conversation RPC', () {
    testWidgets('Check get_current_user_conversation_summaries RPC', (tester) async {
      await initSupabase();
      final client = Supabase.instance.client;

      // Sign in as trucker
      await client.auth.signInWithPassword(
        email: 'trucker@example.com',
        password: 'Tabish%%Khan721',
      );

      debugPrint('Calling get_current_user_conversation_summaries RPC...');

      try {
        final response = await client.rpc('get_current_user_conversation_summaries');
        debugPrint('RPC response type: ${response.runtimeType}');
        debugPrint('RPC response: $response');
        
        if (response is List) {
          debugPrint('Response is a List with ${response.length} items');
        } else if (response is Map) {
          debugPrint('Response is a Map: $response');
        } else {
          debugPrint('Response is: $response');
        }
      } catch (e, stackTrace) {
        debugPrint('RPC error: $e');
        debugPrint('Stack trace: $stackTrace');
      }

      await client.auth.signOut();
      expect(true, isTrue);
    });
  });
}
