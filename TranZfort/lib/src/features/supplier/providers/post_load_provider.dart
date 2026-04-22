import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../l10n/app_localizations.dart';
import '../data/supplier_load_models.dart';
import '../data/supplier_load_repository.dart';
import '../data/supplier_location_services.dart';

const List<String> postLoadMaterials = <String>[
  'Coal',
  'Steel',
  'Cement',
  'Grains',
  'Fertilizer',
  'Machinery',
  'Other',
];

const List<String> postLoadBodyTypes = <String>[
  'Any',
  'Open',
  'Container',
  'Trailer',
  'Tanker',
  'Refrigerated',
];

const List<int> postLoadTyreOptions = <int>[6, 10, 12, 14, 16, 18, 22];
const List<int> postLoadTruckShortcuts = <int>[1, 5, 10, 25];

class PostLoadState {
  final String originCity;
  final String originLocation;
  final String destinationCity;
  final String destinationLocation;
  final List<PlaceSuggestion> originSuggestions;
  final List<PlaceSuggestion> destinationSuggestions;
  final PlaceSuggestion? selectedOrigin;
  final PlaceSuggestion? selectedDestination;
  final bool isSearchingOrigin;
  final bool isSearchingDestination;
  final bool isResolvingRoute;
  final RoutePreview? routePreview;
  final String material;
  final String customMaterial;
  final String weightTonnes;
  final String bodyType;
  final Set<int> selectedTyres;
  final String trucksNeeded;
  final String priceAmount;
  final String priceType;
  final double advancePercentage;
  final DateTime pickupDate;
  final Map<String, String> fieldErrors;
  final bool isSubmitting;
  final AppFailure? submissionFailure;
  final String? lastCreatedLoadId;

  const PostLoadState({
    required this.originCity,
    required this.originLocation,
    required this.destinationCity,
    required this.destinationLocation,
    required this.originSuggestions,
    required this.destinationSuggestions,
    required this.selectedOrigin,
    required this.selectedDestination,
    required this.isSearchingOrigin,
    required this.isSearchingDestination,
    required this.isResolvingRoute,
    required this.routePreview,
    required this.material,
    required this.customMaterial,
    required this.weightTonnes,
    required this.bodyType,
    required this.selectedTyres,
    required this.trucksNeeded,
    required this.priceAmount,
    required this.priceType,
    required this.advancePercentage,
    required this.pickupDate,
    required this.fieldErrors,
    required this.isSubmitting,
    required this.submissionFailure,
    required this.lastCreatedLoadId,
  });

  factory PostLoadState.initial() {
    final today = DateTime.now();
    return PostLoadState(
      originCity: '',
      originLocation: '',
      destinationCity: '',
      destinationLocation: '',
      originSuggestions: const <PlaceSuggestion>[],
      destinationSuggestions: const <PlaceSuggestion>[],
      selectedOrigin: null,
      selectedDestination: null,
      isSearchingOrigin: false,
      isSearchingDestination: false,
      isResolvingRoute: false,
      routePreview: null,
      material: postLoadMaterials.first,
      customMaterial: '',
      weightTonnes: '',
      bodyType: postLoadBodyTypes.first,
      selectedTyres: const <int>{},
      trucksNeeded: '1',
      priceAmount: '',
      priceType: 'per_ton',
      advancePercentage: 80,
      pickupDate: DateTime(today.year, today.month, today.day),
      fieldErrors: const <String, String>{},
      isSubmitting: false,
      submissionFailure: null,
      lastCreatedLoadId: null,
    );
  }

  PostLoadState copyWith({
    String? originCity,
    String? originLocation,
    String? destinationCity,
    String? destinationLocation,
    List<PlaceSuggestion>? originSuggestions,
    List<PlaceSuggestion>? destinationSuggestions,
    PlaceSuggestion? selectedOrigin,
    PlaceSuggestion? selectedDestination,
    bool? clearSelectedOrigin,
    bool? clearSelectedDestination,
    bool? isSearchingOrigin,
    bool? isSearchingDestination,
    bool? isResolvingRoute,
    RoutePreview? routePreview,
    bool? clearRoutePreview,
    String? material,
    String? customMaterial,
    String? weightTonnes,
    String? bodyType,
    Set<int>? selectedTyres,
    String? trucksNeeded,
    String? priceAmount,
    String? priceType,
    double? advancePercentage,
    DateTime? pickupDate,
    Map<String, String>? fieldErrors,
    bool? isSubmitting,
    AppFailure? submissionFailure,
    bool? clearSubmissionFailure,
    String? lastCreatedLoadId,
    bool? clearLastCreatedLoadId,
  }) {
    return PostLoadState(
      originCity: originCity ?? this.originCity,
      originLocation: originLocation ?? this.originLocation,
      destinationCity: destinationCity ?? this.destinationCity,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      originSuggestions: originSuggestions ?? this.originSuggestions,
      destinationSuggestions: destinationSuggestions ?? this.destinationSuggestions,
      selectedOrigin: clearSelectedOrigin == true ? null : selectedOrigin ?? this.selectedOrigin,
      selectedDestination: clearSelectedDestination == true ? null : selectedDestination ?? this.selectedDestination,
      isSearchingOrigin: isSearchingOrigin ?? this.isSearchingOrigin,
      isSearchingDestination: isSearchingDestination ?? this.isSearchingDestination,
      isResolvingRoute: isResolvingRoute ?? this.isResolvingRoute,
      routePreview: clearRoutePreview == true ? null : routePreview ?? this.routePreview,
      material: material ?? this.material,
      customMaterial: customMaterial ?? this.customMaterial,
      weightTonnes: weightTonnes ?? this.weightTonnes,
      bodyType: bodyType ?? this.bodyType,
      selectedTyres: selectedTyres ?? this.selectedTyres,
      trucksNeeded: trucksNeeded ?? this.trucksNeeded,
      priceAmount: priceAmount ?? this.priceAmount,
      priceType: priceType ?? this.priceType,
      advancePercentage: advancePercentage ?? this.advancePercentage,
      pickupDate: pickupDate ?? this.pickupDate,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionFailure: clearSubmissionFailure == true ? null : submissionFailure ?? this.submissionFailure,
      lastCreatedLoadId: clearLastCreatedLoadId == true ? null : lastCreatedLoadId ?? this.lastCreatedLoadId,
    );
  }
}

class PostLoadController extends StateNotifier<PostLoadState> {
  final SupplierLoadRepository _repository;
  final SupplierLocationService _locationService;

  PostLoadController(this._repository, this._locationService) : super(PostLoadState.initial());

  Future<void> searchOriginCity(String query) async {
    state = state.copyWith(
      originCity: query,
      clearSelectedOrigin: true,
      clearRoutePreview: true,
      isSearchingOrigin: query.trim().length >= 2,
      fieldErrors: _withoutErrors(const <String>['origin_city']),
      clearSubmissionFailure: true,
      clearLastCreatedLoadId: true,
    );

    if (query.trim().length < 2) {
      state = state.copyWith(originSuggestions: const <PlaceSuggestion>[], isSearchingOrigin: false);
      return;
    }

    final suggestions = await _locationService.searchCities(query);
    state = state.copyWith(originSuggestions: suggestions, isSearchingOrigin: false);
  }

  Future<void> searchDestinationCity(String query) async {
    state = state.copyWith(
      destinationCity: query,
      clearSelectedDestination: true,
      clearRoutePreview: true,
      isSearchingDestination: query.trim().length >= 2,
      fieldErrors: _withoutErrors(const <String>['destination_city']),
      clearSubmissionFailure: true,
      clearLastCreatedLoadId: true,
    );

    if (query.trim().length < 2) {
      state = state.copyWith(destinationSuggestions: const <PlaceSuggestion>[], isSearchingDestination: false);
      return;
    }

    final suggestions = await _locationService.searchCities(query);
    state = state.copyWith(destinationSuggestions: suggestions, isSearchingDestination: false);
  }

  Future<PlaceSuggestion> selectOriginSuggestion(PlaceSuggestion suggestion) async {
    final resolved = await _locationService.resolveSuggestion(suggestion);
    state = state.copyWith(
      originCity: resolved.city,
      originSuggestions: const <PlaceSuggestion>[],
      selectedOrigin: resolved,
      fieldErrors: _withoutErrors(const <String>['origin_city']),
      clearSubmissionFailure: true,
      clearLastCreatedLoadId: true,
    );
    await _refreshRoutePreview();
    return resolved;
  }

  Future<PlaceSuggestion> selectDestinationSuggestion(PlaceSuggestion suggestion) async {
    final resolved = await _locationService.resolveSuggestion(suggestion);
    state = state.copyWith(
      destinationCity: resolved.city,
      destinationSuggestions: const <PlaceSuggestion>[],
      selectedDestination: resolved,
      fieldErrors: _withoutErrors(const <String>['destination_city']),
      clearSubmissionFailure: true,
      clearLastCreatedLoadId: true,
    );
    await _refreshRoutePreview();
    return resolved;
  }

  void setOriginLocation(String value) {
    state = state.copyWith(
      originLocation: value,
      fieldErrors: _withoutErrors(const <String>['origin_label']),
      clearSubmissionFailure: true,
      clearLastCreatedLoadId: true,
    );
  }

  void setDestinationLocation(String value) {
    state = state.copyWith(
      destinationLocation: value,
      fieldErrors: _withoutErrors(const <String>['destination_label']),
      clearSubmissionFailure: true,
      clearLastCreatedLoadId: true,
    );
  }

  void setMaterial(String? value) {
    if (value == null) {
      return;
    }

    // Clear customMaterial when switching away from "Other"
    final shouldClearCustom = value != 'Other';
    state = state.copyWith(
      material: value,
      customMaterial: shouldClearCustom ? '' : null,
      fieldErrors: _withoutErrors(const <String>['material', 'custom_material']),
      clearSubmissionFailure: true,
      clearLastCreatedLoadId: true,
    );
  }

  void setCustomMaterial(String value) {
    state = state.copyWith(
      customMaterial: value,
      fieldErrors: _withoutErrors(const <String>['custom_material']),
      clearSubmissionFailure: true,
      clearLastCreatedLoadId: true,
    );
  }

  void setWeightTonnes(String value) {
    state = state.copyWith(
      weightTonnes: value,
      fieldErrors: _withoutErrors(const <String>['weight_tonnes']),
      clearSubmissionFailure: true,
      clearLastCreatedLoadId: true,
    );
  }

  void setBodyType(String? value) {
    if (value == null) {
      return;
    }

    state = state.copyWith(clearSubmissionFailure: true, clearLastCreatedLoadId: true, bodyType: value);
  }

  void toggleTyre(int? tyre) {
    if (tyre == null) {
      state = state.copyWith(selectedTyres: <int>{}, clearSubmissionFailure: true, clearLastCreatedLoadId: true);
      return;
    }

    final next = Set<int>.from(state.selectedTyres);
    if (next.contains(tyre)) {
      next.remove(tyre);
    } else {
      next.add(tyre);
    }

    state = state.copyWith(selectedTyres: next, clearSubmissionFailure: true, clearLastCreatedLoadId: true);
  }

  void setTrucksNeeded(String value) {
    state = state.copyWith(
      trucksNeeded: value,
      fieldErrors: _withoutErrors(const <String>['trucks_needed']),
      clearSubmissionFailure: true,
      clearLastCreatedLoadId: true,
    );
  }

  void setPriceAmount(String value) {
    state = state.copyWith(
      priceAmount: value,
      fieldErrors: _withoutErrors(const <String>['price_amount']),
      clearSubmissionFailure: true,
      clearLastCreatedLoadId: true,
    );
  }

  void setPriceType(String value) {
    state = state.copyWith(
      priceType: value,
      fieldErrors: _withoutErrors(const <String>['price_type']),
      clearSubmissionFailure: true,
      clearLastCreatedLoadId: true,
    );
  }

  void setAdvancePercentage(double value) {
    state = state.copyWith(
      advancePercentage: value,
      fieldErrors: _withoutErrors(const <String>['advance_percentage']),
      clearSubmissionFailure: true,
      clearLastCreatedLoadId: true,
    );
  }

  void setPickupDate(DateTime value) {
    state = state.copyWith(
      pickupDate: DateTime(value.year, value.month, value.day),
      fieldErrors: _withoutErrors(const <String>['pickup_date']),
      clearSubmissionFailure: true,
      clearLastCreatedLoadId: true,
    );
  }

  Future<Result<String>> submit([AppLocalizations? l10n]) async {
    if (state.isSubmitting) {
      return const Failure<String>(
        BusinessRuleFailure(message: 'Load submission is already in progress'),
      );
    }

    final fieldErrors = _validate(l10n);
    if (fieldErrors.isNotEmpty) {
      state = state.copyWith(
        fieldErrors: fieldErrors,
        clearSubmissionFailure: true,
        clearLastCreatedLoadId: true,
      );
      return Failure<String>(
        ValidationFailure(
          message: 'Please correct the highlighted load details',
          fieldErrors: fieldErrors,
        ),
      );
    }

    state = state.copyWith(
      isSubmitting: true,
      fieldErrors: const <String, String>{},
      clearSubmissionFailure: true,
      clearLastCreatedLoadId: true,
    );

    final dto = CreateLoadDto(
      originLabel: state.originLocation.trim(),
      originCity: state.selectedOrigin?.city ?? state.originCity.trim(),
      originState: state.selectedOrigin?.state,
      originLat: state.selectedOrigin?.lat,
      originLng: state.selectedOrigin?.lng,
      destinationLabel: state.destinationLocation.trim(),
      destinationCity: state.selectedDestination?.city ?? state.destinationCity.trim(),
      destinationState: state.selectedDestination?.state,
      destinationLat: state.selectedDestination?.lat,
      destinationLng: state.selectedDestination?.lng,
      routeDistanceKm: state.routePreview?.distanceKm,
      routeDurationMinutes: state.routePreview?.durationMinutes,
      routePolyline: null,
      routeSnapshotSource: state.routePreview?.source,
      material: state.material == 'Other' ? state.customMaterial.trim() : state.material,
      weightTonnes: double.parse(state.weightTonnes.trim()),
      requiredBodyType: state.bodyType == 'Any' ? null : state.bodyType,
      requiredTyres: state.selectedTyres.isEmpty ? null : (state.selectedTyres.toList()..sort()),
      trucksNeeded: int.parse(state.trucksNeeded.trim()),
      priceAmount: double.parse(state.priceAmount.trim()),
      priceType: state.priceType,
      advancePercentage: state.advancePercentage.round(),
      pickupDate: state.pickupDate,
    );

    final result = await _repository.createLoad(dto);
    state = state.copyWith(
      isSubmitting: false,
      submissionFailure: result.failureOrNull,
      lastCreatedLoadId: result.valueOrNull,
    );
    return result;
  }

  Map<String, String> _validate(AppLocalizations? l10n) {
    final errors = <String, String>{};

    if (state.originCity.trim().isEmpty) {
      errors['origin_city'] = l10n?.postLoadValidationOriginCityRequired ?? 'Origin city is required';
    }
    if (state.originLocation.trim().isEmpty) {
      errors['origin_label'] = l10n?.postLoadValidationOriginLocationRequired ?? 'Origin location is required';
    }
    if (state.destinationCity.trim().isEmpty) {
      errors['destination_city'] = l10n?.postLoadValidationDestinationCityRequired ?? 'Destination city is required';
    }
    if (state.destinationLocation.trim().isEmpty) {
      errors['destination_label'] = l10n?.postLoadValidationDestinationLocationRequired ?? 'Destination location is required';
    }
    if (state.material.trim().isEmpty) {
      errors['material'] = l10n?.postLoadValidationMaterialRequired ?? 'Material is required';
    }
    if (state.material == 'Other' && state.customMaterial.trim().isEmpty) {
      errors['custom_material'] = 'Please specify the material';
    }

    final weight = double.tryParse(state.weightTonnes.trim());
    if (weight == null || weight <= 0 || weight > 100) {
      errors['weight_tonnes'] = l10n?.postLoadValidationWeightRange ?? 'Weight must be between 0 and 100 tonnes';
    }

    final trucksNeeded = int.tryParse(state.trucksNeeded.trim());
    if (trucksNeeded == null || trucksNeeded < 1) {
      errors['trucks_needed'] = l10n?.postLoadValidationTrucksNeeded ?? 'At least one truck is required';
    }

    final price = double.tryParse(state.priceAmount.trim());
    if (price == null || price <= 0) {
      errors['price_amount'] = l10n?.postLoadValidationPricePositive ?? 'Price must be greater than zero';
    }

    if (state.priceType != 'fixed' && state.priceType != 'per_ton') {
      errors['price_type'] = l10n?.postLoadValidationPriceType ?? 'Invalid price type';
    }

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedPickup = DateTime(state.pickupDate.year, state.pickupDate.month, state.pickupDate.day);
    if (normalizedPickup.isBefore(normalizedToday)) {
      errors['pickup_date'] = l10n?.postLoadValidationPickupDatePast ?? 'Pickup date cannot be in the past';
    }

    return errors;
  }

  Map<String, String> _withoutErrors(List<String> keys) {
    final next = Map<String, String>.from(state.fieldErrors);
    for (final key in keys) {
      next.remove(key);
    }
    return next;
  }

  Future<void> _refreshRoutePreview() async {
    final origin = state.selectedOrigin;
    final destination = state.selectedDestination;
    if (origin == null || destination == null) {
      state = state.copyWith(clearRoutePreview: true);
      return;
    }

    state = state.copyWith(isResolvingRoute: true, clearRoutePreview: true);
    final preview = await _locationService.fetchRoutePreview(origin: origin, destination: destination);
    state = state.copyWith(isResolvingRoute: false, routePreview: preview);
  }
}

final postLoadProvider = StateNotifierProvider.autoDispose<PostLoadController, PostLoadState>((ref) {
  return PostLoadController(
    ref.watch(supplierLoadRepositoryProvider),
    ref.watch(supplierLocationServiceProvider),
  );
});
