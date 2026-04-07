import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../models/load_filters.dart';
import 'shared_providers.dart';

class FindLoadsState {
  final List<Map<String, dynamic>> results;
  final List<Map<String, dynamic>> myTrucks;
  final bool isSearching;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final LoadFilters filters;
  final Map<String, dynamic> searchMeta;
  final bool isRefreshing;

  const FindLoadsState({
    this.results = const [],
    this.myTrucks = const [],
    this.isSearching = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.filters = const LoadFilters(),
    this.searchMeta = const {},
    this.isRefreshing = false,
  });

  FindLoadsState copyWith({
    List<Map<String, dynamic>>? results,
    List<Map<String, dynamic>>? myTrucks,
    bool? isSearching,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    LoadFilters? filters,
    Map<String, dynamic>? searchMeta,
    bool? isRefreshing,
  }) {
    return FindLoadsState(
      results: results ?? this.results,
      myTrucks: myTrucks ?? this.myTrucks,
      isSearching: isSearching ?? this.isSearching,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      filters: filters ?? this.filters,
      searchMeta: searchMeta ?? this.searchMeta,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class FindLoadsNotifier extends StateNotifier<FindLoadsState> {
  final Ref _ref;
  int _currentPage = 1;

  FindLoadsNotifier(this._ref) : super(const FindLoadsState());

  Future<void> initialize() async {
    await Future.wait([
      _loadMyTrucks(),
      searchLoads(refresh: true),
    ]);
  }

  Future<void> _loadMyTrucks() async {
    final user = _ref.read(authSessionProvider).value?.session?.user;
    if (user == null) return;

    final result = await _ref.read(loadRepositoryProvider).getVerifiedTrucks(user.id);
    
    switch (result) {
      case Success(data: final trucks):
        state = state.copyWith(myTrucks: trucks);
      case Failure(debugMessage: final msg):
        state = state.copyWith(error: msg ?? 'Failed to load trucks');
    }
  }

  Future<void> searchLoads({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      state = state.copyWith(
        isSearching: true,
        error: null,
        isRefreshing: true,
        results: [],
      );
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    final user = _ref.read(authSessionProvider).value?.session?.user;
    if (user == null) {
      state = state.copyWith(
        isSearching: false,
        isLoadingMore: false,
        error: 'Not authenticated',
      );
      return;
    }

    final result = await _ref.read(loadRepositoryProvider).findLoads(
      page: _currentPage,
      pageSize: 50,
      originCity: state.filters.originCity,
      destinationCity: state.filters.destinationCity,
      material: state.filters.material,
      truckType: state.filters.truckType,
      sortBy: state.filters.sortBy,
    );

    switch (result) {
      case Success(data: final loads):
        final newLoads = List<Map<String, dynamic>>.from(loads);
        
        state = state.copyWith(
          results: refresh ? newLoads : [...state.results, ...newLoads],
          isSearching: false,
          isLoadingMore: false,
          hasMore: newLoads.length >= 50,
          isRefreshing: false,
        );
        
        if (!refresh) _currentPage++;
        break;
      case Failure(debugMessage: final msg):
        state = state.copyWith(
          isSearching: false,
          isLoadingMore: false,
          error: msg ?? 'Failed to search loads',
          isRefreshing: false,
        );
        break;
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isSearching) return;
    await searchLoads();
  }

  void updateFilters(LoadFilters filters) {
    state = state.copyWith(filters: filters);
    searchLoads(refresh: true);
  }

  void clearFilters() {
    updateFilters(const LoadFilters());
  }

  Future<void> refresh() async {
    await Future.wait([
      _loadMyTrucks(),
      searchLoads(refresh: true),
    ]);
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

    switch (result) {
      case Success(data: final data):
        return data;
      case Failure():
        return <Map<String, dynamic>>[];
    }
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
        state = AsyncError(msg ?? 'Failed to deactivate load', StackTrace.current);
        return false;
    }
  }

  Future<bool> bookLoad(String parentLoadId) async {
    // 1. Check Auth
    final authState = _ref.read(authSessionProvider).value;
    final user = authState?.session?.user;

    if (user == null) {
      state = AsyncError('Not authenticated', StackTrace.current);
      return false;
    }

    // 2. Check Verification Gate
    final profile = await _ref.read(userProfileProvider.future);
    final verificationStatus = (profile?['verification_status'] ?? '').toString().toLowerCase();
    
    if (verificationStatus != 'verified') {
      state = AsyncError('You must be verified to book loads', StackTrace.current);
      return false;
    }

    // 3. Check Trucks
    final myTrucks = _ref.read(findLoadsProvider).myTrucks;

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
        state = const AsyncData(null);
        _ref.invalidate(findLoadsProvider);
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Failed to book load', StackTrace.current);
        return false;
    }
  }
}

final loadActionProvider =
    StateNotifierProvider<LoadActionNotifier, AsyncValue<void>>((ref) {
      return LoadActionNotifier(ref);
    });
