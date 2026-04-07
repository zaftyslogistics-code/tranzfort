import 'dart:math' as math;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/config/maps_config.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/repositories/load_repository.dart';
import '../../../core/services/city_search_service.dart'
    show CitySearchService, CitySuggestion, CitySearchMode;
import '../../../core/services/google_routes_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/osrm_service.dart';
import '../../../core/services/trip_costing_service.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/utils/coordinate_utils.dart';
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

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(ref.watch(mapsConfigProvider));
});

final weatherByLocationProvider =
    FutureProvider.family<WeatherSnapshot?, ({double lat, double lng})>((
      ref,
      location,
    ) {
      return ref
          .read(weatherServiceProvider)
          .getCurrentWeather(lat: location.lat, lng: location.lng);
    });

class LoadRouteMeta {
  final int? driveTimeMinutes;
  final double? tollEstimate;
  final double? fuelEstimate;

  const LoadRouteMeta({
    this.driveTimeMinutes,
    this.tollEstimate,
    this.fuelEstimate,
  });
}

final loadRouteMetaProvider =
    FutureProvider.family<LoadRouteMeta?, String>((ref, loadId) async {
      final result = await ref.read(loadRepositoryProvider).getLoadDetail(loadId);
      final load = switch (result) {
        Success(data: final data) => data,
        Failure() => null,
      };
      if (load == null) {
        return null;
      }

      final origin = CoordinateUtils.toLatLngFromMap(
        load,
        latKey: 'origin_lat',
        lngKey: 'origin_lng',
      );
      final destination = CoordinateUtils.toLatLngFromMap(
        load,
        latKey: 'dest_lat',
        lngKey: 'dest_lng',
      );

      if (origin == null || destination == null) {
        return null;
      }

      final route = await GoogleRoutesService(
        ref.read(mapsConfigProvider),
        OsrmService(),
      ).computeRoute(origin, destination);

      return LoadRouteMeta(
        driveTimeMinutes:
            route.durationSeconds == null ? null : (route.durationSeconds! / 60).round(),
        tollEstimate: route.tollEstimate,
        fuelEstimate: route.fuelConsumptionLiters,
      );
    });

final loadDestinationWeatherProvider =
    FutureProvider.family<WeatherSnapshot?, String>((ref, loadId) async {
      final result = await ref.read(loadRepositoryProvider).getLoadDetail(loadId);
      final load = switch (result) {
        Success(data: final data) => data,
        Failure() => null,
      };
      if (load == null) {
        return null;
      }
      final destination = CoordinateUtils.parseLatLngFromMap(
        load,
        latKey: 'dest_lat',
        lngKey: 'dest_lng',
      );
      if (destination == null) {
        return null;
      }
      return ref
          .read(weatherServiceProvider)
          .getCurrentWeather(lat: destination.lat, lng: destination.lng);
    });

final savedSearchesProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final user = ref.watch(authSessionProvider).value?.session?.user;
    if (user == null) return const [];

    final result = await ref
        .watch(loadRepositoryProvider)
        .getSavedSearches(user.id);

    return switch (result) {
      Success(data: final data) => data,
      Failure() => const <Map<String, dynamic>>[],
    };
  },
);

class SavedSearchActionNotifier extends StateNotifier<AsyncValue<void>> {
  SavedSearchActionNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<bool> saveSearch({
    required String originCity,
    required String destinationCity,
    required String material,
    required String truckType,
    required String sortBy,
  }) async {
    final user = _ref.read(authSessionProvider).value?.session?.user;
    if (user == null) {
      return false;
    }

    state = const AsyncLoading();
    final result = await _ref
        .read(loadRepositoryProvider)
        .saveSearch(
          userId: user.id,
          originCity: originCity,
          destinationCity: destinationCity,
          material: material,
          truckType: truckType,
          sortBy: sortBy,
        );

    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(savedSearchesProvider);
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Failed to save search', StackTrace.current);
        return false;
    }
  }

  Future<bool> deleteSavedSearch(String savedSearchId) async {
    state = const AsyncLoading();
    final result = await _ref
        .read(loadRepositoryProvider)
        .deleteSavedSearch(savedSearchId);

    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(savedSearchesProvider);
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Failed to delete saved search', StackTrace.current);
        return false;
    }
  }
}

final savedSearchActionProvider =
    StateNotifierProvider<SavedSearchActionNotifier, AsyncValue<void>>(
      (ref) => SavedSearchActionNotifier(ref),
    );

class CitySearchState {
  final bool isLoading;
  final List<CitySuggestion> suggestions;
  final CitySearchMode? searchMode;
  final String? errorMessage;

  const CitySearchState({
    this.isLoading = false,
    this.suggestions = const [],
    this.searchMode,
    this.errorMessage,
  });

  CitySearchState copyWith({
    bool? isLoading,
    List<CitySuggestion>? suggestions,
    CitySearchMode? searchMode,
    String? errorMessage,
  }) {
    return CitySearchState(
      isLoading: isLoading ?? this.isLoading,
      suggestions: suggestions ?? this.suggestions,
      searchMode: searchMode ?? this.searchMode,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CitySearchNotifier extends StateNotifier<CitySearchState> {
  final CitySearchService _service;
  Timer? _debounce;

  CitySearchNotifier(this._service) : super(const CitySearchState());

  Future<void> search(String query) async {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      state = const CitySearchState(suggestions: []);
      return;
    }

    state = state.copyWith(isLoading: true);
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      final result = await _service.search(query);
      state = CitySearchState(
        isLoading: false,
        suggestions: result.suggestions,
        searchMode: result.mode,
        errorMessage: result.errorMessage,
      );
    });
  }

  void clear() {
    _debounce?.cancel();
    state = const CitySearchState(suggestions: []);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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
  final double? tollEstimate;

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
    this.tollEstimate,
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
      (requiredTruckType?.trim().isNotEmpty ?? false) &&
      requiredTyres.isNotEmpty &&
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
    double? tollEstimate,
    String? material,
    double? weightTonnes,
    String? requiredTruckType,
    List<int>? requiredTyres,
    double? price,
    String? priceType,
    int? advancePercentage,
    DateTime? pickupDate,
    int? trucksNeeded,
    bool clearRouteMeta = false,
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
      distanceKm: clearRouteMeta ? null : (distanceKm ?? this.distanceKm),
      durationHours: clearRouteMeta ? null : (durationHours ?? this.durationHours),
      tollEstimate: clearRouteMeta ? null : (tollEstimate ?? this.tollEstimate),
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
    unawaited(_recalculateDistance());
  }

  void setDestination(CitySuggestion city) {
    state = state.copyWith(
      destinationCity: city.city,
      destinationState: city.state,
      destinationLat: city.lat,
      destinationLng: city.lng,
      clearError: true,
    );
    unawaited(_recalculateDistance());
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

    try {
      final profile = await _ref.read(userProfileProvider.future);
      final status = (profile?['verification_status'] ?? '').toString().trim().toLowerCase();
      final role = (profile?['user_role_type'] ?? '').toString().trim().toLowerCase();
      if (role == 'supplier' && status != 'verified') {
        state = state.copyWith(lastError: AppFailureType.validation);
        return false;
      }
    } catch (_) {
      state = state.copyWith(lastError: AppFailureType.validation);
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

  Future<void> _recalculateDistance() async {
    final originLat = state.originLat;
    final originLng = state.originLng;
    final destinationLat = state.destinationLat;
    final destinationLng = state.destinationLng;

    if (originLat == null ||
        originLng == null ||
        destinationLat == null ||
        destinationLng == null) {
      state = state.copyWith(
        clearRouteMeta: true,
      );
      return;
    }

    // Set deterministic offline fallback first so UI/test state is populated
    // even if network-based route providers are slow or unavailable.
    final fallbackKm = _haversineKm(
      originLat,
      originLng,
      destinationLat,
      destinationLng,
    );
    final fallbackDurationHours = fallbackKm / 48;
    state = state.copyWith(
      distanceKm: fallbackKm,
      durationHours: fallbackDurationHours,
      tollEstimate: null,
    );

    final routeService = GoogleRoutesService(
      _ref.read(mapsConfigProvider),
      OsrmService(),
    );
    final route = await routeService.computeRoute(
      LatLng(originLat, originLng),
      LatLng(destinationLat, destinationLng),
    );

    if (!mounted) {
      return;
    }

    if (route.distanceKm != null && route.durationHours != null) {
      state = state.copyWith(
        distanceKm: route.distanceKm,
        durationHours: route.durationHours,
        tollEstimate: route.tollEstimate,
      );
      return;
    }

    // Keep previously applied fallback values when richer route data is unavailable.
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

final verifiedTrucksProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
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
});

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

  int get activeFilterCount {
    var count = 0;
    if (originCity.trim().isNotEmpty) count++;
    if (destinationCity.trim().isNotEmpty) count++;
    if (material.trim().isNotEmpty) count++;
    if (truckType.trim().isNotEmpty) count++;
    if (sortBy != 'newest') count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;
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
        final normalized = _normalizeLoads(data);
        state = state.copyWith(
          isSearching: false,
          results: normalized,
          hasMorePages: normalized.length >= 50,
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
        final normalized = _normalizeLoads(data);
        state = state.copyWith(
          isLoadingMore: false,
          currentPage: nextPage,
          results: [...state.results, ...normalized],
          hasMorePages: normalized.length >= 50,
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

  List<Map<String, dynamic>> _normalizeLoads(List<Map<String, dynamic>> loads) {
    return loads
        .map((load) => {...load, 'poster_label': _posterLabel(load)})
        .toList(growable: false);
  }

  String _posterLabel(Map<String, dynamic> load) {
    final supplier = load['supplier'];
    if (supplier is Map<String, dynamic>) {
      final company = (supplier['company_name'] ?? '').toString().trim();
      if (company.isNotEmpty) {
        return company;
      }

      final profile = supplier['profiles'];
      if (profile is Map<String, dynamic>) {
        final fullName = (profile['full_name'] ?? '').toString().trim();
        if (fullName.isNotEmpty) {
          return fullName;
        }
      }
    }

    return 'Verified Supplier';
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
        distanceKm: CoordinateUtils.parseDouble(load['distance_km']),
        loadWeightTonnes: CoordinateUtils.parseDouble(load['weight_tonnes']),
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
