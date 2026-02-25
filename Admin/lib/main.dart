import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/core/config/supabase_config.dart';
import 'src/core/routing/admin_router.dart';
import 'src/core/theme/admin_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supabaseConfig = SupabaseConfig.fromEnvironment();
  if (supabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: supabaseConfig.url,
      anonKey: supabaseConfig.anonKey,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        supabaseConfiguredProvider.overrideWithValue(supabaseConfig.isConfigured),
      ],
      child: const TranZfortAdminApp(),
    ),
  );
}

class TranZfortAdminApp extends ConsumerWidget {
  const TranZfortAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: 'TranZfort Admin',
      theme: AdminTheme.light,
      routerConfig: router,
    );
  }
}
