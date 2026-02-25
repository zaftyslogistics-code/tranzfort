import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'src/core/config/supabase_config.dart';
import 'src/core/routing/app_router.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/notifications/providers/fcm_token_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  final supabaseConfig = SupabaseConfig.fromEnvironment();
  if (supabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: supabaseConfig.url,
        anonKey: supabaseConfig.anonKey,
      );
    } catch (e) {
      // Ignore initialization errors if it's already initialized
      debugPrint('Supabase initialization error: $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        supabaseConfiguredProvider.overrideWithValue(
          supabaseConfig.isConfigured,
        ),
      ],
      child: const TranZfortApp(),
    ),
  );
}

class TranZfortApp extends ConsumerWidget {
  const TranZfortApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Initialize FCM Token fetching when the app starts
    // This safely handles permission requesting internally
    ref.watch(fcmTokenProvider);

    return MaterialApp.router(
      title: 'TranZfort',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
