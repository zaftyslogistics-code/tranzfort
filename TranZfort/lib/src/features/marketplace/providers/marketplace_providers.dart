import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/maps_config.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/repositories/load_repository.dart';
import '../../../core/services/city_search_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/trip_costing_service.dart';
import '../../auth/providers/auth_providers.dart';

final mapsConfigProvider = Provider<MapsConfig>((ref) {
  return MapsConfig.fromEnvironment();
});

final loadRepositoryProvider = Provider<LoadRepository>((ref) {
  return LoadRepository(ref.watch(supabaseClientProvider));
});

final citySearchServiceProvider = Provider<CitySearchService>((ref) {
  return CitySearchService(ref.watch(mapsConfigProvider));
});

final tripCostingServiceProvider = Provider<TripCostingService>((ref) {
  return TripCostingService();
});

final marketplaceLocationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

class CitySearchState {
  final bool isLoading;
  final List<CitySuggestion> suggestions;

  const CitySearchState({this.isLoading = false, this.suggestions = const []});

  CitySearchState copyWith({
    bool? isLoading,
    List<CitySuggestion>? suggestions,
  }) {
    return CitySearchState(
      isLoading: isLoading ?? this.isLoading,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}

class CitySearchNotifier extends StateNotifier<CitySearchState> {
  final CitySearchService _service;

  CitySearchNotifier(this._service) : super(const CitySearchState());

  Future<void> search(String query) async {
    if (query.trim().length < 2) {
      state = const CitySearchState(suggestions: []);
      return;
    }

    state = state.copyWith(isLoading: true);
    final suggestions = await _service.search(query);
    state = state.copyWith(isLoading: false, suggestions: suggestions);
  }

  void clear() {
    state = const CitySearchState(suggestions: []);
  }
}

final citySearchProvider =
    StateNotifierProvider.family<CitySearchNotifier, CitySearchState, String>((
      ref,
      _,
    ) {
      return CitySearchNotifier(ref.watch(citySearchServiceProvider));
    });

class PostLoadState {
  final int currentStep;
  final bool isSubmitting;
  final AppFailureType? lastError;

  final String? originCity;
  final String? originState;
  final double? originLat;
  final double? originLng;

  final String? destinationCity;
  final String? destinationState;
  final double? destinationLat;
  final double? destinationLng;

  final double? distanceKm;
  final double? durationHours;

  final String material;
  final double weightTonnes;
  final String? requiredTruckType;
  final List<int> requiredTyres;

  final double price;
  final String priceType;
  final int advancePercentage;
  final DateTime pickupDate;
  final int trucksNeeded;

  PostLoadState({
    this.currentStep = 0,
    this.isSubmitting = false,
    this.lastError,
    this.originCity,
    this.originState,
    this.originLat,
    this.originLng,
    this.destinationCity,
    this.destinationState,
    this.destinationLat,
    this.destinationLng,
    this.distanceKm,
    this.durationHours,
    this.material = 'Coal',
    this.weightTonnes = 25,
    this.requiredTruckType,
    this.requiredTyres = const [],
    this.price = 62500,
    this.priceType = 'negotiable',
    this.advancePercentage = 80,
    DateTime? pickupDate,
    this.trucksNeeded = 1,
  }) : pickupDate = pickupDate ?? DateTime.now().add(const Duration(days: 1));

  bool get canGoNextStepOne =>
      (originCity?.isNotEmpty ?? false) &&
      (destinationCity?.isNotEmpty ?? false);

  bool get canSubmit =>
      canGoNextStepOne &&
      material.trim().isNotEmpty &&
      weightTonnes > 0 &&
      price > 0 &&
      trucksNeeded >= 1;

  PostLoadState copyWith({
    int? currentStep,
    bool? isSubmitting,
    AppFailureType? lastError,
    bool clearError = false,
    String? originCity,
    String? originState,
    double? originLat,
    double? originLng,
    String? destinationCity,
    String? destinationState,
    double? destinationLat,
    double? destinationLng,
    double? distanceKm,
    double? durationHours,
    String? material,
    double? weightTonnes,
    String? requiredTruckType,
    List<int>? requiredTyres,
    double? price,
    String? priceType,
    int? advancePercentage,
    DateTime? pickupDate,
    int? trucksNeeded,
  }) {
    return PostLoadState(
      currentStep: currentStep ?? this.currentStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastError: clearError ? null : (lastError ?? this.lastError),
      originCity: originCity ?? this.originCity,
      originState: originState ?? this.originState,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      destinationCity: destinationCity ?? this.destinationCity,
      destinationState: destinationState ?? this.destinationState,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      distanceKm: distanceKm ?? this.distanceKm,
      durationHours: durationHours ?? this.durationHours,
      material: material ?? this.material,
      weightTonnes: weightTonnes ?? this.weightTonnes,
      requiredTruckType: requiredTruckType ?? this.requiredTruckType,
      requiredTyres: requiredTyres ?? this.requiredTyres,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      advancePercentage: advancePercentage ?? this.advancePercentage,
      pickupDate: pickupDate ?? this.pickupDate,
      trucksNeeded: trucksNeeded ?? this.trucksNeeded,
    );
  }
}

class PostLoadNotifier extends StateNotifier<PostLoadState> {
  final Ref _ref;

  PostLoadNotifier(this._ref) : super(PostLoadState());

  void nextStep() {
    if (state.currentStep == 0 && !state.canGoNextStepOne) {
      return;
    }
    if (state.currentStep < 3) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        clearError: true,
      );
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
        clearError: true,
      );
    }
  }

  void setOrigin(CitySuggestion city) {
    state = state.copyWith(
      originCity: city.city,
      originState: city.state,
      originLat: city.lat,
      originLng: city.lng,
      clearError: true,
    );
    _recalculateDistance();
  }

  void setDestination(CitySuggestion city) {
    state = state.copyWith(
      destinationCity: city.city,
      destinationState: city.state,
      destinationLat: city.lat,
      destinationLng: city.lng,
      clearError: true,
    );
    _recalculateDistance();
  }

  void setMaterial(String value) {
    state = state.copyWith(material: value, clearError: true);
  }

  void setWeight(double value) {
    state = state.copyWith(weightTonnes: value, clearError: true);
  }

  void setTruckType(String? value) {
    state = state.copyWith(requiredTruckType: value, clearError: true);
  }

  void toggleTyre(int tyre) {
    final current = [...state.requiredTyres];
    if (current.contains(tyre)) {
      current.remove(tyre);
    } else {
      current.add(tyre);
      current.sort();
    }
    state = state.copyWith(requiredTyres: current, clearError: true);
  }

  void setPrice(double value) {
    state = state.copyWith(price: value, clearError: true);
  }

  void setPriceType(String value) {
    state = state.copyWith(priceType: value, clearError: true);
  }

  void setAdvance(int value) {
    state = state.copyWith(
      advancePercentage: value.clamp(0, 100),
      clearError: true,
    );
  }

  void setPickupDate(DateTime value) {
    state = state.copyWith(pickupDate: value, clearError: true);
  }

  void setTrucksNeeded(int value) {
    final trucks = value < 1 ? 1 : value;
    state = state.copyWith(trucksNeeded: trucks, clearError: true);
  }

  Future<bool> submitLoad() async {
    if (!state.canSubmit) {
      state = state.copyWith(lastError: AppFailureType.validation);
      return false;
    }

    final user = _ref.read(authSessionProvider).value?.session?.user;
    if (user == null) {
      state = state.copyWith(lastError: AppFailureType.auth);
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    final payload = <String, dynamic>{
      'origin_city': state.originCity,
      'origin_state': state.originState,
      'origin_lat': state.originLat,
      'origin_lng': state.originLng,
      'dest_city': state.destinationCity,
      'dest_state': state.destinationState,
      'dest_lat': state.destinationLat,
      'dest_lng': state.destinationLng,
      'distance_km': state.distanceKm,
      'duration_hours': state.durationHours,
      'material': state.material,
      'weight_tonnes': state.weightTonnes,
      'required_truck_type': state.requiredTruckType,
      'required_tyres': state.requiredTyres,
      'price': state.price,
      'price_type': state.priceType,
      'advance_percentage': state.advancePercentage,
      'pickup_date': state.pickupDate.toIso8601String().split('T').first,
      'trucks_needed': state.trucksNeeded,
    };

    final result = await _ref
        .read(loadRepositoryProvider)
        .createLoad(supplierId: user.id, payload: payload);

    switch (result) {
      case Success():
        state = PostLoadState();
        _ref.invalidate(myLoadsProvider(false));
        return true;
      case Failure(type: final type):
        state = state.copyWith(isSubmitting: false, lastError: type);
        return false;
    }
  }

  void _recalculateDistance() {
    final originLat = state.originLat;
    final originLng = state.originLng;
    final destinationLat = state.destinationLat;
    final destinationLng = state.destinationLng;

    if (originLat == null ||
        originLng == null ||
        destinationLat == null ||
        destinationLng == null) {
      state = state.copyWith(distanceKm: null, durationHours: null);
      return;
    }

    final km = _haversineKm(
      originLat,
      originLng,
      destinationLat,
      destinationLng,
    );
    final durationHours = km / 48;
    state = state.copyWith(distanceKm: km, durationHours: durationHours);
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a =
        (sinHalfSquared(dLat)) +
        (_cos(lat1) * _cos(lat2) * sinHalfSquared(dLon));
    final c = 2 * _atan2Sqrt(a, 1 - a);
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * 0.017453292519943295;

  double _cos(double degrees) => math.cos(_degreesToRadians(degrees));

  double sinHalfSquared(double angle) {
    final sinHalf = math.sin(angle / 2);
    return sinHalf * sinHalf;
  }

  double _atan2Sqrt(double a, double b) =>
      math.atan2(math.sqrt(a), math.sqrt(b));
}

final postLoadProvider = StateNotifierProvider<PostLoadNotifier, PostLoadState>(
  (ref) {
    return PostLoadNotifier(ref);
  },
);

final verifiedTrucksProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final user = ref.watch(authSessionProvider).value?.session?.user;
    if (user == null) {
      return const [];
    }

    final result = await ref
        .watch(loadRepositoryProvider)
        .getVerifiedTrucks(user.id);

    return switch (result) {
      Success(data: final data) => data,
      Failure() => const <Map<String, dynamic>>[],
    };
  },
);

class LoadFilters {
  final String originCity;
  final String destinationCity;
  final String material;
  final String truckType;
  final String sortBy;

  const LoadFilters({
    this.originCity = '',
    this.destinationCity = '',
    this.material = '',
    this.truckType = '',
    this.sortBy = 'newest',
  });

  LoadFilters copyWith({
    String? originCity,
    String? destinationCity,
    String? material,
    String? truckType,
    String? sortBy,
  }) {
    return LoadFilters(
      originCity: originCity ?? this.originCity,
      destinationCity: destinationCity ?? this.destinationCity,
      material: material ?? this.material,
      truckType: truckType ?? this.truckType,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class FindLoadsState {
  final bool isSearching;
  final bool isLoadingMore;
  final bool hasMorePages;
  final int currentPage;
  final List<Map<String, dynamic>> results;
  final List<Map<String, dynamic>> myTrucks;
  final LoadFilters filters;
  final AppFailureType? lastError;

  const FindLoadsState({
    this.isSearching = false,
    this.isLoadingMore = false,
    this.hasMorePages = true,
    this.currentPage = 1,
    this.results = const [],
    this.myTrucks = const [],
    this.filters = const LoadFilters(),
    this.lastError,
  });

  FindLoadsState copyWith({
    bool? isSearching,
    bool? isLoadingMore,
    bool? hasMorePages,
    int? currentPage,
    List<Map<String, dynamic>>? results,
    List<Map<String, dynamic>>? myTrucks,
    LoadFilters? filters,
    AppFailureType? lastError,
    bool clearError = false,
  }) {
    return FindLoadsState(
      isSearching: isSearching ?? this.isSearching,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      currentPage: currentPage ?? this.currentPage,
      results: results ?? this.results,
      myTrucks: myTrucks ?? this.myTrucks,
      filters: filters ?? this.filters,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class FindLoadsNotifier extends StateNotifier<FindLoadsState> {
  final Ref _ref;

  FindLoadsNotifier(this._ref) : super(const FindLoadsState());

  Future<void> initialize() async {
    await _loadMyTrucks();
    await search(state.filters);
  }

  Future<void> search(LoadFilters filters) async {
    state = state.copyWith(
      isSearching: true,
      currentPage: 1,
      hasMorePages: true,
      filters: filters,
      clearError: true,
    );

    final result = await _ref
        .read(loadRepositoryProvider)
        .findLoads(
          page: 1,
          pageSize: 50,
          originCity: filters.originCity,
          destinationCity: filters.destinationCity,
          material: filters.material,
          truckType: filters.truckType,
          sortBy: filters.sortBy,
        );

    switch (result) {
      case Success(data: final data):
        state = state.copyWith(
          isSearching: false,
          results: data,
          hasMorePages: data.length >= 50,
          currentPage: 1,
        );
      case Failure(type: final type):
        state = state.copyWith(
          isSearching: false,
          lastError: type,
          results: const [],
          hasMorePages: false,
        );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMorePages || state.isSearching) {
      return;
    }

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await _ref
        .read(loadRepositoryProvider)
        .findLoads(
          page: nextPage,
          pageSize: 50,
          originCity: state.filters.originCity,
          destinationCity: state.filters.destinationCity,
          material: state.filters.material,
          truckType: state.filters.truckType,
          sortBy: state.filters.sortBy,
        );

    switch (result) {
      case Success(data: final data):
        state = state.copyWith(
          isLoadingMore: false,
          currentPage: nextPage,
          results: [...state.results, ...data],
          hasMorePages: data.length >= 50,
        );
      case Failure(type: final type):
        state = state.copyWith(isLoadingMore: false, lastError: type);
    }
  }

  Future<void> resetFilters() async {
    await search(const LoadFilters());
  }

  Future<void> _loadMyTrucks() async {
    final user = _ref.read(authSessionProvider).value?.session?.user;
    if (user == null) {
      return;
    }

    final result = await _ref
        .read(loadRepositoryProvider)
        .getVerifiedTrucks(user.id);
    switch (result) {
      case Success(data: final data):
        state = state.copyWith(myTrucks: data);
      case Failure():
        state = state.copyWith(myTrucks: const []);
    }
  }
}

final findLoadsProvider =
    StateNotifierProvider<FindLoadsNotifier, FindLoadsState>((ref) {
      final notifier = FindLoadsNotifier(ref);
      Future.microtask(notifier.initialize);
      return notifier;
    });

final myLoadsProvider = FutureProvider.family<List<Map<String, dynamic>>, bool>(
  (ref, completed) async {
    final user = ref.watch(authSessionProvider).value?.session?.user;
    if (user == null) {
      return const [];
    }

    final result = await ref
        .watch(loadRepositoryProvider)
        .myLoads(supplierId: user.id, completed: completed);

    return switch (result) {
      Success(data: final data) => data,
      Failure() => const <Map<String, dynamic>>[],
    };
  },
);

class LoadActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  LoadActionNotifier(this._ref) : super(const AsyncData(null));

  Future<bool> deactivateLoad(String loadId) async {
    state = const AsyncLoading();
    final result = await _ref
        .read(loadRepositoryProvider)
        .deactivateLoad(loadId);
    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(myLoadsProvider(false));
        _ref.invalidate(myLoadsProvider(true));
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(
          msg ?? 'Unable to deactivate load',
          StackTrace.current,
        );
        return false;
    }
  }

  Future<bool> approveBooking(String childLoadId, String parentLoadId) async {
    state = const AsyncLoading();
    final result = await _ref
        .read(loadRepositoryProvider)
        .approveBooking(childLoadId);
    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(loadDetailProvider(parentLoadId));
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(
          msg ?? 'Unable to approve booking',
          StackTrace.current,
        );
        return false;
    }
  }

  Future<bool> rejectBooking(String childLoadId, String parentLoadId) async {
    state = const AsyncLoading();
    final result = await _ref
        .read(loadRepositoryProvider)
        .rejectBooking(childLoadId);
    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(loadDetailProvider(parentLoadId));
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(
          msg ?? 'Unable to reject booking',
          StackTrace.current,
        );
        return false;
    }
  }

  Future<bool> confirmDelivery(String childLoadId, String parentLoadId) async {
    state = const AsyncLoading();
    final result = await _ref
        .read(loadRepositoryProvider)
        .confirmDeliveryForChildLoad(childLoadId);
    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(loadDetailProvider(parentLoadId));
        _ref.invalidate(myLoadsProvider(false));
        _ref.invalidate(myLoadsProvider(true));
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(
          msg ?? 'Unable to confirm delivery',
          StackTrace.current,
        );
        return false;
    }
  }

  Future<bool> bookLoad(String parentLoadId) async {
    final user = _ref.read(authSessionProvider).value?.session?.user;
    final myTrucks = _ref.read(findLoadsProvider).myTrucks;

    if (user == null) {
      state = AsyncError('Not authenticated', StackTrace.current);
      return false;
    }

    if (myTrucks.isEmpty) {
      state = AsyncError('No verified trucks available', StackTrace.current);
      return false;
    }

    final truckId = myTrucks.first['id']?.toString();
    if (truckId == null || truckId.isEmpty) {
      state = AsyncError('Invalid truck', StackTrace.current);
      return false;
    }

    return bookLoadWithTruck(parentLoadId: parentLoadId, truckId: truckId);
  }

  Future<bool> bookLoadWithTruck({
    required String parentLoadId,
    required String truckId,
  }) async {
    final user = _ref.read(authSessionProvider).value?.session?.user;

    if (user == null) {
      state = AsyncError('Not authenticated', StackTrace.current);
      return false;
    }

    if (truckId.isEmpty) {
      state = AsyncError('Invalid truck', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final result = await _ref
        .read(loadRepositoryProvider)
        .bookLoad(
          parentLoadId: parentLoadId,
          truckerId: user.id,
          truckId: truckId,
        );

    switch (result) {
      case Success():
        try {
          final captured = await _ref
              .read(marketplaceLocationServiceProvider)
              .captureCurrentLocation();
          if (captured != null) {
            await _ref
                .read(loadRepositoryProvider)
                .updateProfileLastKnownLocation(
                  profileId: user.id,
                  lat: captured.lat,
                  lng: captured.lng,
                );
          }
        } catch (_) {
          // GPS capture is non-blocking for booking action.
        }

        state = const AsyncData(null);
        _ref.invalidate(findLoadsProvider);
        _ref.invalidate(verifiedTrucksProvider);
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Unable to book load', StackTrace.current);
        return false;
    }
  }
}

final loadActionProvider =
    StateNotifierProvider<LoadActionNotifier, AsyncValue<void>>((ref) {
      return LoadActionNotifier(ref);
    });

final loadDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  loadId,
) async {
  final loadResult = await ref
      .watch(loadRepositoryProvider)
      .getLoadDetail(loadId);
  final load = switch (loadResult) {
    Success(data: final data) => data,
    Failure() => <String, dynamic>{},
  };

  if (load.isEmpty) {
    return const <String, dynamic>{};
  }

  final parentId = (load['parent_load_id'] ?? load['id']).toString();
  final childrenResult = await ref
      .watch(loadRepositoryProvider)
      .getChildLoads(parentId);
  final children = switch (childrenResult) {
    Success(data: final data) => data,
    Failure() => <Map<String, dynamic>>[],
  };

  final dieselPriceResult = await ref
      .watch(loadRepositoryProvider)
      .getDieselPrice((load['origin_state'] ?? '').toString());
  final dieselPrice = switch (dieselPriceResult) {
    Success(data: final data) => data,
    Failure() => 90.0,
  };

  final tripCostResult = ref
      .read(tripCostingServiceProvider)
      .estimate(
        distanceKm: (load['distance_km'] as num?)?.toDouble(),
        loadWeightTonnes: (load['weight_tonnes'] as num?)?.toDouble(),
        payloadKg: 10000,
        emptyMileageKmpl: 4.0,
        loadedMileageKmpl: 2.5,
        axleCount: 2,
        dieselPricePerLitre: dieselPrice,
      );

  final tripCost = switch (tripCostResult) {
    Success(data: final data) => {
      'diesel': data.dieselCost,
      'toll': data.tollCost,
      'total': data.totalCost,
      'mileage': data.estimatedMileage,
    },
    Failure() => <String, dynamic>{},
  };

  return {'load': load, 'children': children, 'trip_cost': tripCost};
});
