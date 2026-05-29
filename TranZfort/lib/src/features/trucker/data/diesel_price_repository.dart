import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';

class DieselPriceEntry {
  final String state;
  final double pricePerLitre;

  const DieselPriceEntry({
    required this.state,
    required this.pricePerLitre,
  });

  factory DieselPriceEntry.fromMap(Map<String, dynamic> map) {
    final raw = map['price_per_litre'];
    final fallback = AppConfig.defaultDieselPricePerLitre;
    final price = raw is num
        ? raw.toDouble()
        : double.tryParse((raw ?? '$fallback').toString()) ?? fallback;
    return DieselPriceEntry(
      state: (map['state'] ?? '').toString(),
      pricePerLitre: price,
    );
  }
}

abstract class DieselPriceBackend {
  Future<List<Map<String, dynamic>>> fetchAllPrices();
}

class SupabaseDieselPriceBackend implements DieselPriceBackend {
  final SupabaseClient? _client;

  const SupabaseDieselPriceBackend(this._client);

  @override
  Future<List<Map<String, dynamic>>> fetchAllPrices() async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('diesel_prices')
        .select('state, price_per_litre')
        .order('state');

    return response.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}

class DieselPriceRepository {
  final DieselPriceBackend _backend;
  Map<String, double>? _cache;

  DieselPriceRepository(this._backend);

  Future<Result<Map<String, double>>> fetchPriceMap({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) {
      return Success<Map<String, double>>(_cache!);
    }

    try {
      final rows = await _backend.fetchAllPrices();
      _cache = {
        for (final row in rows)
          DieselPriceEntry.fromMap(row).state.trim().toLowerCase(): DieselPriceEntry.fromMap(row).pricePerLitre,
      };
      return Success<Map<String, double>>(_cache!);
    } catch (error, stackTrace) {
      return Failure<Map<String, double>>(_mapError(error, stackTrace));
    }
  }

  Future<double> lookupPricePerLitre(String? state) async {
    final normalized = (state ?? '').trim().toLowerCase();
    if (normalized.isEmpty) {
      return AppConfig.defaultDieselPricePerLitre;
    }

    final result = await fetchPriceMap();
    return result.valueOrNull?[normalized] ?? AppConfig.defaultDieselPricePerLitre;
  }

  /// Diesel price for trip earnings estimates.
  ///
  /// Uses [AppConfig.defaultDieselPricePerLitre] when state is unknown or the reference
  /// table still has legacy values below the product default.
  static double estimateDieselPricePerLitre(Map<String, double> priceMap, String? originState) {
    final configured = AppConfig.defaultDieselPricePerLitre;
    final key = (originState ?? '').trim().toLowerCase();
    if (key.isEmpty) {
      return configured;
    }
    final fromMap = priceMap[key];
    if (fromMap == null) {
      return configured;
    }
    return fromMap < configured ? configured : fromMap;
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) =>
      mapSupabaseError(error, stackTrace);
}

final dieselPriceRepositoryProvider = Provider<DieselPriceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DieselPriceRepository(SupabaseDieselPriceBackend(client));
});

final dieselPriceMapProvider = FutureProvider<Map<String, double>>((ref) async {
  final result = await ref.watch(dieselPriceRepositoryProvider).fetchPriceMap();
  return result.when(
    success: (value) => value,
    failure: (failure) => throw failure,
  );
});
