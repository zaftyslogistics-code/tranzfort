import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _hasSeenSplashKey = 'has_seen_splash';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakFirstOpenGreeting();
    });
  }

  Future<void> _speakFirstOpenGreeting() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenSplash = prefs.getBool(_hasSeenSplashKey) ?? false;
    if (hasSeenSplash) {
      return;
    }

    await prefs.setBool(_hasSeenSplashKey, true);
    if (!mounted) {
      return;
    }

    await ref
        .read(ttsServiceProvider)
        .speak('Namaste, TranZfort mein aapka swagat hai.');
  }

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(supabaseConfiguredProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                Image.asset(
                  'assets/images/splash-screen-logo.png',
                  height: 130,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.local_shipping,
                      size: 96,
                      color: AppColors.primary,
                    );
                  },
                ),
                const SizedBox(height: 14),
                Image.asset(
                  'assets/images/main-logo-transparent.png',
                  height: 46,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                Text(
                  'TranZfort',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                if (!configured)
                  Text(
                    'Supabase is not configured. Run with --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=... to continue.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.neutral),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
