import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/lifecycle_status_constants.dart';
import '../../../core/error/app_failure.dart';
import '../data/supplier_load_models.dart';
import '../data/supplier_load_repository.dart';

enum MyLoadsTab {
  active,
  completed,
}

class MyLoadsState {
  final MyLoadsTab selectedTab;
  final List<Load> loads;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final AppFailure? failure;

  const MyLoadsState({
    required this.selectedTab,
    required this.loads,
    required this.isInitialLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.page,
    required this.failure,
  });

  factory MyLoadsState.initial() {
    return const MyLoadsState(
      selectedTab: MyLoadsTab.active,
      loads: <Load>[],
      isInitialLoading: true,
      isLoadingMore: false,
      hasMore: true,
      page: 1,
      failure: null,
    );
  }

  MyLoadsState copyWith({
    MyLoadsTab? selectedTab,
    List<Load>? loads,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return MyLoadsState(
      selectedTab: selectedTab ?? this.selectedTab,
      loads: loads ?? this.loads,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

class MyLoadsController extends StateNotifier<MyLoadsState> {
  static const Duration _minLoadingDuration = Duration(milliseconds: 300);
  static const Duration _errorDebounceDuration = Duration(milliseconds: 300);

  final SupplierLoadRepository _repository;
  static const int _pageSize = 20;
  Timer? _errorDebounceTimer;

  MyLoadsController(this._repository) : super(MyLoadsState.initial()) {
    loadInitial();
  }

  void _scheduleInitialErrorDisplay(AppFailure failure) {
    _errorDebounceTimer?.cancel();
    _errorDebounceTimer = Timer(_errorDebounceDuration, () {
      if (state.loads.isEmpty && !state.isInitialLoading) {
        state = state.copyWith(failure: failure);
      }
    });
  }

  void _cancelErrorDisplay() {
    _errorDebounceTimer?.cancel();
    _errorDebounceTimer = null;
  }

  Future<void> _ensureMinLoadingDuration(DateTime startTime) async {
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < _minLoadingDuration) {
      await Future.delayed(_minLoadingDuration - elapsed);
    }
  }

  Future<void> loadInitial() async {
    _cancelErrorDisplay();
    state = state.copyWith(
      isInitialLoading: true,
      isLoadingMore: false,
      page: 1,
      loads: const <Load>[],
      hasMore: true,
      clearFailure: true,
    );

    final startTime = DateTime.now();
    final result = await _repository.getMyLoads(_filtersFor(state.selectedTab), page: 1);
    await result.when(
      success: (value) async {
        _cancelErrorDisplay();
        await _ensureMinLoadingDuration(startTime);
        state = state.copyWith(
          loads: value,
          isInitialLoading: false,
          hasMore: value.length >= _pageSize,
          page: 1,
          clearFailure: true,
        );
      },
      failure: (failure) async {
        await _ensureMinLoadingDuration(startTime);
        _scheduleInitialErrorDisplay(failure);
        state = state.copyWith(
          isInitialLoading: false,
          hasMore: false,
        );
      },
    );
  }

  Future<void> selectTab(MyLoadsTab tab) async {
    if (tab == state.selectedTab) {
      return;
    }

    state = state.copyWith(selectedTab: tab);
    await loadInitial();
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearFailure: true);
    final result = await _repository.getMyLoads(_filtersFor(state.selectedTab), page: nextPage);
    result.when(
      success: (value) {
        state = state.copyWith(
          isLoadingMore: false,
          page: nextPage,
          loads: <Load>[...state.loads, ...value],
          hasMore: value.length >= _pageSize,
          clearFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isLoadingMore: false,
          failure: failure,
        );
      },
    );
  }

  LoadFilters _filtersFor(MyLoadsTab tab) {
    return LoadFilters(
      statuses: tab == MyLoadsTab.active
          ? LoadStatuses.supplierViewActive
          : LoadStatuses.completed,
    );
  }

  @override
  void dispose() {
    _errorDebounceTimer?.cancel();
    super.dispose();
  }
}

final myLoadsProvider = StateNotifierProvider.autoDispose<MyLoadsController, MyLoadsState>((ref) {
  return MyLoadsController(ref.watch(supplierLoadRepositoryProvider));
});
