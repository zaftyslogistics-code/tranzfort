import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_marketplace_repository.dart';
import 'package:tranzfort/src/features/tts/data/load_marketplace_card_tts_builder.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';
import 'package:tranzfort/src/l10n/tts_localizations.dart';

void main() {
  final sampleLoad = MarketplaceLoadItem(
    id: 'load-1',
    supplierId: 'supplier-1',
    originLabel: 'Mumbai, MH',
    originCity: 'Mumbai',
    originState: 'MH',
    originLat: 19.076,
    originLng: 72.8777,
    destinationLabel: 'Delhi, DL',
    destinationCity: 'Delhi',
    destinationState: 'DL',
    destinationLat: 28.7041,
    destinationLng: 77.1025,
    routeDistanceKm: 1400,
    routeDurationMinutes: 1440,
    material: 'Coal',
    weightTonnes: 80,
    requiredBodyType: 'open',
    requiredTyres: const [10, 18],
    trucksNeeded: 1,
    trucksBooked: 0,
    priceAmount: 1000,
    priceType: 'per_ton',
    advancePercentage: 20,
    pickupDate: DateTime(2026, 6, 1),
    status: 'active',
    isSuperLoad: false,
    superStatus: '',
    createdAt: DateTime(2026, 5, 29),
  );

  testWidgets('Hindi utterance uses natural route and rate phrasing', (tester) async {
    late String utterance;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('hi'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          TtsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('hi'),
        ],
        home: Builder(
          builder: (context) {
            utterance = const LoadMarketplaceCardTtsBuilder().build(
              load: sampleLoad,
              tts: TtsLocalizations.of(context)!,
              ui: AppLocalizations.of(context)!,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(utterance, contains('Mumbai se Delhi'));
    expect(utterance, contains('Maal Coal'));
    expect(utterance, contains('Bhada 1000 rupaye prati ton'));
    expect(utterance, isNot(contains('per_ton')));
  });

  testWidgets('English utterance uses load-from phrasing', (tester) async {
    late String utterance;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          TtsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('hi'),
        ],
        home: Builder(
          builder: (context) {
            utterance = const LoadMarketplaceCardTtsBuilder().build(
              load: sampleLoad,
              tts: TtsLocalizations.of(context)!,
              ui: AppLocalizations.of(context)!,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(utterance, contains('Load from Mumbai to Delhi'));
    expect(utterance, contains('Material Coal'));
    expect(utterance, contains('rupees per ton'));
  });
}
