import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/core/config/supabase_config.dart';
import 'src/core/logger/app_logger.dart';
import 'src/core/navigation/app_router.dart';
import 'src/core/providers/app_locale_providers.dart';
import 'src/core/providers/connectivity_provider.dart';
import 'src/core/theme/app_colors.dart';
import 'src/core/theme/app_theme.dart';
import 'src/l10n/app_localizations.dart';
import 'src/features/notifications/data/push_token_service.dart';
import 'src/features/notifications/data/push_runtime_service.dart';
import 'src/shared/widgets/feedback_components.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      _configureGlobalErrorHandling();

      try {
        await dotenv.load(fileName: '.env');
      } catch (dotenvError) {
        AppLogger.warning('dotenv.load() failed — continuing with platform env', scope: 'main', error: dotenvError);
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
            title: _bootstrapStartupFailureTitle(),
            message: _bootstrapStartupFailureMessage(),
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
                title: _bootstrapRenderFailureTitle(),
                message: _bootstrapRenderFailureMessage(),
              ),
            ),
          ),
        ),
      ),
    );
  };
}

void _reportUnhandledError(Object error, StackTrace stackTrace) {
  AppLogger.error('Unhandled application error', scope: 'main', error: error, stackTrace: stackTrace);
}

bool _isBootstrapHindi() {
  return ui.PlatformDispatcher.instance.locale.languageCode.trim().toLowerCase() == 'hi';
}

String _bootstrapText({required String english, required String hindi}) {
  return _isBootstrapHindi() ? hindi : english;
}

String _bootstrapStartupFailureTitle() {
  return _bootstrapText(
    english: 'TranZfort startup issue',
    hindi: 'TranZfort स्टार्टअप समस्या',
  );
}

String _bootstrapStartupFailureMessage() {
  return _bootstrapText(
    english: 'The app could not finish startup right now. Restart the app.',
    hindi: 'ऐप अभी पूरी तरह शुरू नहीं हो सका। कृपया ऐप दोबारा शुरू करें।',
  );
}

String _bootstrapRenderFailureTitle() {
  return _bootstrapText(
    english: 'Something went wrong',
    hindi: 'कुछ गलत हो गया',
  );
}

String _bootstrapRenderFailureMessage() {
  return _bootstrapText(
    english: 'A screen failed to render. Restart or retry.',
    hindi: 'एक स्क्रीन रेंडर नहीं हो सकी। कृपया फिर कोशिश करें या ऐप दोबारा शुरू करें।',
  );
}

Future<void> _initializeFirebaseIfAvailable() async {
  try {
    await Firebase.initializeApp();
  } catch (error) {
    AppLogger.warning('Firebase initialization skipped', scope: 'main', error: error);
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
      scaffoldMessengerKey: AppSnackbar.scaffoldMessengerKey,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) {
        return _GlobalProvidersWrapper(
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: AppColors.canvasWash),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      locale: localeState.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}

class _GlobalProvidersWrapper extends ConsumerWidget {
  final Widget child;
  
  const _GlobalProvidersWrapper({required this.child});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;

    return Column(
      children: [
        Expanded(child: child),
        if (!isOnline)
          Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              color: AppColors.error,
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).connectivityOfflineBanner,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

