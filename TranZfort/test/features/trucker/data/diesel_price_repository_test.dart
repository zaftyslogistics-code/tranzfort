import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/config/app_config.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/trucker/data/diesel_price_repository.dart';

class _FakeDieselPriceBackend implements DieselPriceBackend {
  List<Map<String, dynamic>> rows = const <Map<String, dynamic>>[];
  Object? error;

  @override
  Future<List<Map<String, dynamic>>> fetchAllPrices() async {
    if (error != null) {
      throw error!;
    }
    return rows;
  }
}

void main() {
  group('DieselPriceRepository', () {
    test('maps diesel price rows into a lowercase lookup map', () async {
      final backend = _FakeDieselPriceBackend()
        ..rows = const [
          {'state': 'Maharashtra', 'price_per_litre': 92.5},
          {'state': 'Goa', 'price_per_litre': 88.5},
        ];
      final repository = DieselPriceRepository(backend);

      final result = await repository.fetchPriceMap();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?['maharashtra'], 92.5);
      expect(result.valueOrNull?['goa'], 88.5);
    });

    test('returns cached lookup when available', () async {
      final backend = _FakeDieselPriceBackend()
        ..rows = const [
          {'state': 'Maharashtra', 'price_per_litre': 92.5},
        ];
      final repository = DieselPriceRepository(backend);

      await repository.fetchPriceMap();
      backend.rows = const [
        {'state': 'Maharashtra', 'price_per_litre': 95.0},
      ];

      final lookup = await repository.lookupPricePerLitre('Maharashtra');
      expect(lookup, 92.5);
    });

    test('uses default price when state is missing', () async {
      final repository = DieselPriceRepository(_FakeDieselPriceBackend());

      final lookup = await repository.lookupPricePerLitre(null);
      expect(lookup, AppConfig.defaultDieselPricePerLitre);
    });

    test('estimateDieselPricePerLitre floors legacy map values below AppConfig default', () {
      const map = {'maharashtra': 90.0, 'goa': 105.0};

      expect(
        DieselPriceRepository.estimateDieselPricePerLitre(map, 'Maharashtra'),
        AppConfig.defaultDieselPricePerLitre,
      );
      expect(DieselPriceRepository.estimateDieselPricePerLitre(map, 'Goa'), 105.0);
      expect(
        DieselPriceRepository.estimateDieselPricePerLitre(map, null),
        AppConfig.defaultDieselPricePerLitre,
      );
    });

    test('maps network errors', () async {
      final backend = _FakeDieselPriceBackend()
        ..error = const SocketException('offline');
      final repository = DieselPriceRepository(backend);

      final result = await repository.fetchPriceMap(forceRefresh: true);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('maps permission errors', () async {
      final backend = _FakeDieselPriceBackend()
        ..error = const PostgrestException(message: 'forbidden', code: '42501');
      final repository = DieselPriceRepository(backend);

      final result = await repository.fetchPriceMap(forceRefresh: true);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });
}
