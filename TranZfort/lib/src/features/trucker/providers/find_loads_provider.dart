import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../data/trucker_marketplace_repository.dart';

enum FindLoadsTab {
  all,
  superLoads,
}

class FindLoadsState {
  final FindLoadsTab selectedTab;
  final MarketplaceSearchFilters filters;
  final List<MarketplaceLoadItem> loads;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final int? totalCount;
  final AppFailure? failure;

  const FindLoadsState({
    required this.selectedTab,
    required this.filters,
    required this.loads,
    required this.isInitialLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.page,
    this.totalCount,
    required this.failure,
  });

  factory FindLoadsState.initial() {
    return const FindLoadsState(
      selectedTab: FindLoadsTab.all,
      filters: MarketplaceSearchFilters(),
      loads: <MarketplaceLoadItem>[],
      isInitialLoading: true,
      isLoadingMore: false,
      hasMore: true,
      page: 1,
      totalCount: null,
      failure: null,
    );
  }

  FindLoadsState copyWith({
    FindLoadsTab? selectedTab,
    MarketplaceSearchFilters? filters,
    List<MarketplaceLoadItem>? loads,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    int? totalCount,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return FindLoadsState(
      selectedTab: selectedTab ?? this.selectedTab,
      filters: filters ?? this.filters,
      loads: loads ?? this.loads,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

class FindLoadsController extends StateNotifier<FindLoadsState> {
  final TruckerMarketplaceRepository _repository;

  FindLoadsController(this._repository) : super(FindLoadsState.initial()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(
      isInitialLoading: true,
      isLoadingMore: false,
      clearFailure: true,
    );

    final result = await _repository.searchLoads(_effectiveFilters(state), page: 1);

    result.when(
      success: (searchResult) {
        state = state.copyWith(
          loads: searchResult.items,
          isInitialLoading: false,
          isLoadingMore: false,
          page: 1,
          hasMore: searchResult.hasMore,
          totalCount: searchResult.total,
          clearFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isInitialLoading: false,
          isLoadingMore: false,
          failure: failure,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearFailure: true);
    final result = await _repository.searchLoads(_effectiveFilters(state), page: nextPage);
    result.when(
      success: (searchResult) {
        state = state.copyWith(
          isLoadingMore: false,
          page: nextPage,
          loads: <MarketplaceLoadItem>[...state.loads, ...searchResult.items],
          hasMore: searchResult.hasMore,
          totalCount: searchResult.total,
          clearFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(isLoadingMore: false, failure: failure);
      },
    );
  }

  Future<void> selectTab(FindLoadsTab tab) async {
    if (tab == state.selectedTab) {
      return;
    }
    state = state.copyWith(selectedTab: tab);
    await loadInitial();
  }

  Future<void> updateFilters(MarketplaceSearchFilters filters) async {
    state = state.copyWith(filters: filters);
    await loadInitial();
  }

  Future<void> resetFilters() async {
    state = state.copyWith(filters: const MarketplaceSearchFilters(), selectedTab: FindLoadsTab.all);
    await loadInitial();
  }

  MarketplaceSearchFilters _effectiveFilters(FindLoadsState state) {
    return state.filters.copyWith(
      superLoadsOnly: state.selectedTab == FindLoadsTab.superLoads || state.filters.superLoadsOnly,
    );
  }
}

final findLoadsProvider = StateNotifierProvider.autoDispose<FindLoadsController, FindLoadsState>((ref) {
  return FindLoadsController(ref.watch(truckerMarketplaceRepositoryProvider));
});
