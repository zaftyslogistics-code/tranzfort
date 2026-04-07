import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../models/load_filters.dart';
import '../providers/marketplace_providers.dart';

class FindLoadsController {
  final WidgetRef ref;
  final void Function(VoidCallback) setState;
  final BuildContext context;

  FindLoadsController({
    required this.ref,
    required this.setState,
    required this.context,
  });

  Future<void> saveSearch({
    required String originCity,
    required String destinationCity,
    required String material,
    required String truckType,
    required String sortBy,
  }) async {
    final l10n = AppLocalizations.of(context);
    final success = await ref
        .read(savedSearchActionProvider.notifier)
        .saveSearch(
          originCity: originCity,
          destinationCity: destinationCity,
          material: material,
          truckType: truckType,
          sortBy: sortBy,
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? l10n.findLoadsSavedSearchSaved
              : l10n.findLoadsSavedSearchSaveFailed,
        ),
      ),
    );
  }

  Future<void> applySavedSearch(
    Map<String, dynamic> saved, {
    required Function(String) setOrigin,
    required Function(String) setDestination,
    required Function(String) setMaterial,
    required Function(String) setTruckType,
    required Function(String) setSortBy,
    required Future<void> Function() search,
  }) async {
    setOrigin((saved['origin_city'] ?? '').toString());
    setDestination((saved['destination_city'] ?? '').toString());
    setState(() {
      setMaterial((saved['material'] ?? '').toString());
      setTruckType((saved['truck_type'] ?? '').toString());
      setSortBy((saved['sort_by'] ?? 'newest').toString());
    });

    await search();
  }

  Future<void> deleteSavedSearch(String id) async {
    final l10n = AppLocalizations.of(context);
    final success = await ref
        .read(savedSearchActionProvider.notifier)
        .deleteSearch(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? l10n.findLoadsSavedSearchDeleted
              : l10n.findLoadsSavedSearchDeleteFailed,
        ),
      ),
    );
  }

  Future<void> search(LoadFilters filters) async {
    ref.read(findLoadsProvider.notifier).updateFilters(filters);
  }

  Future<void> clearFilters({
    required Function() clearOrigin,
    required Function() clearDestination,
    required Function(String) setMaterial,
    required Function(String) setTruckType,
    required Function(String) setSortBy,
  }) async {
    clearOrigin();
    clearDestination();
    setState(() {
      setMaterial('');
      setTruckType('');
      setSortBy('newest');
    });
    ref.read(findLoadsProvider.notifier).clearFilters();
  }

  int calculateActiveFilterCount({
    required String originCity,
    required String destinationCity,
    required String material,
    required String truckType,
    required String sortBy,
  }) {
    var count = 0;
    if (originCity.trim().isNotEmpty) count++;
    if (destinationCity.trim().isNotEmpty) count++;
    if (material.isNotEmpty) count++;
    if (truckType.isNotEmpty) count++;
    if (sortBy != 'newest') count++;
    return count;
  }

  String materialLabel(AppLocalizations l10n, String material) {
    return switch (material) {
      'Coal' => l10n.findLoadsMaterialCoal,
      'Steel' => l10n.findLoadsMaterialSteel,
      'Cement' => l10n.findLoadsMaterialCement,
      'Sand' => l10n.findLoadsMaterialSand,
      '' => l10n.findLoadsAnyMaterial,
      _ => material,
    };
  }

  String truckLabel(AppLocalizations l10n, String truckType) {
    return truckType.isEmpty
        ? l10n.findLoadsAnyTruck
        : truckTypeLabel(l10n, truckType);
  }

  String truckTypeLabel(AppLocalizations l10n, String value) {
    return switch (value) {
      'open' => l10n.postLoadTruckTypeOpen,
      'container' => l10n.postLoadTruckTypeContainer,
      'trailer' => l10n.postLoadTruckTypeTrailer,
      'tanker' => l10n.postLoadTruckTypeTanker,
      _ => value,
    };
  }

  String sortLabel(AppLocalizations l10n, String sortBy) {
    return switch (sortBy) {
      'price_high' => l10n.findLoadsSortPriceHighLow,
      'price_low' => l10n.findLoadsSortPriceLowHigh,
      'pickup_date' => l10n.findLoadsSortPickupDate,
      _ => l10n.findLoadsSortNewest,
    };
  }

  String nextValue(String current, List<String> values) {
    final currentIndex = values.indexOf(current);
    if (currentIndex == -1 || currentIndex == values.length - 1) {
      return values.first;
    }
    return values[currentIndex + 1];
  }

  String buildSummaryText({
    required String originCity,
    required String destinationCity,
    required String material,
    required String truckType,
    required String sortBy,
    required AppLocalizations l10n,
  }) {
    final parts = <String>[];
    
    if (originCity.isNotEmpty) {
      parts.add('${l10n.findLoadsFromLabel}: $originCity');
    }
    if (destinationCity.isNotEmpty) {
      parts.add('${l10n.findLoadsToLabel}: $destinationCity');
    }
    if (material.isNotEmpty) {
      parts.add(materialLabel(l10n, material));
    }
    if (truckType.isNotEmpty) {
      parts.add(truckLabel(l10n, truckType));
    }
    
    if (parts.isEmpty) {
      return l10n.searchLoads;
    }
    
    return parts.join(' • ');
  }
}
