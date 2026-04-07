import 'package:app/src/core/config/supabase_config.dart';
import 'package:app/src/core/routing/app_router.dart';
import 'package:app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class _RouterHost extends ConsumerWidget {
  const _RouterHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User router keyless guard: always stays on splash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
        child: const _RouterHost(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('TranZfort'), findsOneWidget);

    final element = tester.element(find.byType(_RouterHost));
    final container = ProviderScope.containerOf(element);
    final router = container.read(appRouterProvider);

    router.go('/auth');
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('TranZfort'), findsOneWidget);
    expect(find.text('Continue your journey'), findsNothing);
  });
}
