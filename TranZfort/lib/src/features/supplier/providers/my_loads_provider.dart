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
  final SupplierLoadRepository _repository;

  MyLoadsController(this._repository) : super(MyLoadsState.initial()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(
      isInitialLoading: true,
      isLoadingMore: false,
      page: 1,
      loads: const <Load>[],
      hasMore: true,
      clearFailure: true,
    );

    final result = await _repository.getMyLoads(_filtersFor(state.selectedTab), page: 1);
    result.when(
      success: (value) {
        state = state.copyWith(
          loads: value,
          isInitialLoading: false,
          hasMore: value.isNotEmpty,
          page: 1,
          clearFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isInitialLoading: false,
          failure: failure,
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
          hasMore: value.isNotEmpty,
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
}

final myLoadsProvider = StateNotifierProvider.autoDispose<MyLoadsController, MyLoadsState>((ref) {
  return MyLoadsController(ref.watch(supplierLoadRepositoryProvider));
});
