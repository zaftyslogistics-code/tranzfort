import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/theme/app_decorations.dart';
import 'package:tranzfort/src/core/theme/app_spacing.dart';
import 'package:tranzfort/src/features/trucker/presentation/widgets/marketplace_filter_bar.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('Polish UI responsive smoke', () {
    testWidgets('MarketplaceFilterBar fits at 320dp with Any selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 640)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: DecoratedBox(
                  decoration: AppDecorations.inkHeroCard(borderRadius: BorderRadius.zero),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: MarketplaceFilterBar(
                      selectedBodyType: '',
                      selectedTyres: <int>[],
                      onDarkSurface: true,
                      onBodyTypeChanged: _noopString,
                      onTyreToggled: _noopInt,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MarketplaceFilterBar), findsOneWidget);
    });

    testWidgets('MarketplaceFilterBar fits at 320dp with Open + tyre row', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 640)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: DecoratedBox(
                  decoration: AppDecorations.inkHeroCard(borderRadius: BorderRadius.zero),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: MarketplaceFilterBar(
                      selectedBodyType: 'Open',
                      selectedTyres: <int>[10],
                      onDarkSurface: true,
                      onBodyTypeChanged: _noopString,
                      onTyreToggled: _noopInt,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('10'), findsOneWidget);
    });
  });
}

void _noopString(String _) {}
void _noopInt(int _) {}
