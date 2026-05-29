import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_models.dart';
import 'package:tranzfort/src/features/tts/data/supplier_load_list_card_tts_builder.dart';
import 'package:tranzfort/src/features/tts/data/trip_list_card_tts_builder.dart';
import 'package:tranzfort/src/l10n/tts_localizations.dart';

void main() {
  testWidgets('supplier load list Hindi summary', (tester) async {
    late String utterance;
    final load = Load(
      id: 'load-1',
      originLabel: 'Mumbai',
      destinationLabel: 'Delhi',
      material: 'Coal',
      weightTonnes: 80,
      trucksNeeded: 1,
      trucksBooked: 0,
      priceAmount: 1000,
      priceType: 'per_ton',
      pickupDate: DateTime(2026, 6, 1),
      status: 'active',
      requiredBodyType: 'open',
      requiredTyres: const [10],
      isSuperLoad: false,
      superStatus: '',
      publishedAt: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('hi'),
        localizationsDelegates: const [
          TtsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('hi')],
        home: Builder(
          builder: (context) {
            utterance = const SupplierLoadListCardTtsBuilder().build(
              load: load,
              tts: TtsLocalizations.of(context)!,
              statusLabel: 'सक्रिय',
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(utterance, contains('Mumbai se Delhi'));
    expect(utterance, contains('Coal'));
  });

  testWidgets('trip card English summary', (tester) async {
    late String utterance;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          TtsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('hi')],
        home: Builder(
          builder: (context) {
            utterance = const TripListCardTtsBuilder().build(
              tts: TtsLocalizations.of(context)!,
              routeLabel: 'Mumbai to Delhi',
              material: 'Coal',
              stageLabel: 'In transit',
              truckNumber: 'MH12AB1234',
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(utterance, contains('Mumbai to Delhi'));
    expect(utterance, contains('MH12AB1234'));
  });
}
