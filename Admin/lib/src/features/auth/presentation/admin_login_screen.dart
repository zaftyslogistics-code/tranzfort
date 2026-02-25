import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_config.dart';

class AdminLoginScreen extends ConsumerWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configured = ref.watch(supabaseConfiguredProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings, size: 72),
              const SizedBox(height: 16),
              const Text('TranZfort Admin'),
              const SizedBox(height: 24),
              if (!configured)
                const Text(
                  'Supabase is not configured. Run with --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=... to continue.',
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
