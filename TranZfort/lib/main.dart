import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/core/config/supabase_config.dart';
import 'src/core/navigation/app_router.dart';
import 'src/core/providers/app_locale_providers.dart';
import 'src/core/theme/app_theme.dart';
import 'src/l10n/app_localizations.dart';
import 'src/features/notifications/data/push_token_service.dart';
import 'src/features/notifications/data/push_runtime_service.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      _configureGlobalErrorHandling();

      try {
        await dotenv.load(fileName: '.env');
      } catch (dotenvError) {
        debugPrint('dotenv.load() failed — continuing with platform env: $dotenvError');
      }

      final config = SupabaseConfig.fromEnvironment();

      if (config.isConfigured) {
        await Supabase.initialize(
          url: config.url,
          anonKey: config.anonKey,
        );
      }

      await _initializeFirebaseIfAvailable();

      runApp(const ProviderScope(child: TranZfortApp()));
    } catch (error, stackTrace) {
      _reportUnhandledError(error, stackTrace);
      runApp(
        ProviderScope(
          child: _StartupFailureApp(
            title: 'TranZfort startup issue / स्टार्टअप समस्या',
            message: 'The app could not finish startup right now. Restart the app.\nApp अभी स्टार्ट नहीं हो सका। App पुनः आरंभ करें।',
          ),
        ),
      );
    }
  }, _reportUnhandledError);
}

void _configureGlobalErrorHandling() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _reportUnhandledError(details.exception, details.stack ?? StackTrace.current);
  };

  ErrorWidget.builder = (details) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _FatalErrorView(
                title: 'Something went wrong / कुछ गलत हो गया',
                message: 'A screen failed to render. Restart or retry.\nस्क्रीन रेंडर नहीं हो सकी। पुनः प्रयास करें।',
              ),
            ),
          ),
        ),
      ),
    );
  };
}

void _reportUnhandledError(Object error, StackTrace stackTrace) {
  debugPrint('Unhandled application error: $error');
  debugPrintStack(stackTrace: stackTrace);
}

Future<void> _initializeFirebaseIfAvailable() async {
  try {
    await Firebase.initializeApp();
  } catch (error) {
    debugPrint('Firebase initialization skipped: $error');
  }
}

class _StartupFailureApp extends StatelessWidget {
  final String title;
  final String message;

  const _StartupFailureApp({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _FatalErrorView(title: title, message: message),
            ),
          ),
        ),
      ),
    );
  }
}

class _FatalErrorView extends StatelessWidget {
  final String title;
  final String message;

  const _FatalErrorView({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TranZfortApp extends ConsumerWidget {
  const TranZfortApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushTokenLifecycleProvider);
    ref.watch(pushRuntimeLifecycleProvider);
    final router = ref.watch(appRouterProvider);
    final localeState = ref.watch(appLocaleProvider);
    ref.listen<String?>(pendingPushRouteProvider, (previous, next) {
      if (next == null || next.isEmpty) {
        return;
      }

      router.go(next);
      ref.read(pendingPushRouteProvider.notifier).state = null;
    });

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: localeState.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}

