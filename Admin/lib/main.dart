import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/core/navigation/admin_router.dart';
import 'src/core/theme/admin_theme.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      _configureGlobalErrorHandling();

      await dotenv.load(fileName: '.env');

      final url = dotenv.env['SUPABASE_URL'] ?? '';
      final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (url.isNotEmpty && key.isNotEmpty) {
        await Supabase.initialize(url: url, anonKey: key);
      }

      runApp(const ProviderScope(child: AdminApp()));
    } catch (error, stackTrace) {
      _reportUnhandledError(error, stackTrace);
      runApp(
        ProviderScope(
          child: _StartupFailureApp(
            title: 'TranZfort Admin startup issue',
            message: 'The admin app could not finish startup right now. Check environment and backend initialization, then restart the app.',
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
                title: 'Something went wrong',
                message: 'The admin app hit a runtime error while rendering this screen. Restart the app or retry the previous action.',
              ),
            ),
          ),
        ),
      ),
    );
  };
}

void _reportUnhandledError(Object error, StackTrace stackTrace) {
  debugPrint('Unhandled admin application error: $error');
  debugPrintStack(stackTrace: stackTrace);
}

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: 'TranZfort Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.dark,
      locale: const Locale('en'),
      supportedLocales: const <Locale>[Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routerConfig: router,
    );
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
