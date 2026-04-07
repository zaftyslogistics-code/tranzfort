import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'src/core/config/supabase_config.dart';
import 'src/core/routing/app_router.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/notifications/providers/fcm_token_provider.dart';
import 'src/features/settings/providers/settings_provider.dart';
import 'src/l10n/app_localizations.dart';
import 'src/shared/widgets/connectivity_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('No .env file found, falling back to --dart-define');
  }

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
    final settings = ref.watch(settingsProvider);

    ref.watch(fcmTokenProvider);

    return MaterialApp.router(
      title: 'TranZfort',
      theme: AppTheme.light,
      locale: Locale(settings.language),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('hi')],
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            physics: const ClampingScrollPhysics(),
          ),
          child: ConnectivityBanner(child: child ?? const SizedBox.shrink()),
        );
      },
      routerConfig: router,
    );
  }
}
