import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_operational_case_repository.dart';

class AdminOperationalCaseQueueState {
  final OperationalCaseQuery query;
  final bool isLoading;
  final List<AdminOperationalCaseItem> items;
  final bool hasMore;
  final OperationalCaseCounts counts;

  const AdminOperationalCaseQueueState({
    required this.query,
    required this.isLoading,
    required this.items,
    required this.hasMore,
    required this.counts,
  });

  factory AdminOperationalCaseQueueState.initial() {
    return AdminOperationalCaseQueueState(
      query: const OperationalCaseQuery(statusFilter: OperationalCaseStatusFilter.all, search: ''),
      isLoading: false,
      items: const [],
      hasMore: false,
      counts: OperationalCaseCounts.empty(),
    );
  }

  AdminOperationalCaseQueueState copyWith({
    OperationalCaseQuery? query,
    bool? isLoading,
    List<AdminOperationalCaseItem>? items,
    bool? hasMore,
    OperationalCaseCounts? counts,
  }) {
    return AdminOperationalCaseQueueState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      counts: counts ?? this.counts,
    );
  }
}

class AdminOperationalCaseActionState {
  final bool isLoading;

  const AdminOperationalCaseActionState({this.isLoading = false});
}

class AdminOperationalCaseQueueController extends AutoDisposeAsyncNotifier<AdminOperationalCaseQueueState> {
  @override
  Future<AdminOperationalCaseQueueState> build() async {
    final query = AdminOperationalCaseQueueState.initial().query;
    final page = await ref.read(adminOperationalCaseRepositoryProvider).getOperationalCases(query);
    return AdminOperationalCaseQueueState.initial().copyWith(
      query: query,
      items: page.items,
      hasMore: page.hasMore,
      counts: page.counts,
    );
  }

  Future<void> updateSearch(String value) async {
    final current = state.value ?? AdminOperationalCaseQueueState.initial();
    await _reload(current.query.copyWith(search: value, page: 0));
  }

  Future<void> updateStatusFilter(OperationalCaseStatusFilter filter) async {
    final current = state.value ?? AdminOperationalCaseQueueState.initial();
    await _reload(current.query.copyWith(statusFilter: filter, page: 0));
  }

  Future<void> refresh() async {
    final current = state.value ?? AdminOperationalCaseQueueState.initial();
    await _reload(current.query.copyWith(page: 0));
  }

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || current.isLoading || !current.hasMore) {
      return;
    }
    state = AsyncData(current.copyWith(isLoading: true));
    final nextQuery = current.query.copyWith(page: current.query.page + 1);
    final page = await ref.read(adminOperationalCaseRepositoryProvider).getOperationalCases(nextQuery);
    state = AsyncData(
      current.copyWith(
        query: nextQuery,
        isLoading: false,
        items: [...current.items, ...page.items],
        hasMore: page.hasMore,
        counts: page.counts,
      ),
    );
  }

  Future<void> _reload(OperationalCaseQuery query) async {
    final current = state.value ?? AdminOperationalCaseQueueState.initial();
    state = AsyncData(current.copyWith(query: query, isLoading: true));
    final page = await ref.read(adminOperationalCaseRepositoryProvider).getOperationalCases(query);
    state = AsyncData(
      current.copyWith(
        query: query,
        isLoading: false,
        items: page.items,
        hasMore: page.hasMore,
        counts: page.counts,
      ),
    );
  }
}

class AdminOperationalCaseActionController extends AutoDisposeNotifier<AdminOperationalCaseActionState> {
  @override
  AdminOperationalCaseActionState build() => const AdminOperationalCaseActionState();

  Future<bool> claimCase(String caseId) async {
    state = const AdminOperationalCaseActionState(isLoading: true);
    try {
      return await ref.read(adminOperationalCaseRepositoryProvider).claimCase(caseId);
    } finally {
      state = const AdminOperationalCaseActionState(isLoading: false);
    }
  }

  Future<bool> releaseCase(String caseId) async {
    state = const AdminOperationalCaseActionState(isLoading: true);
    try {
      return await ref.read(adminOperationalCaseRepositoryProvider).releaseCase(caseId);
    } finally {
      state = const AdminOperationalCaseActionState(isLoading: false);
    }
  }

  Future<bool> transitionCase({
    required String caseId,
    required OperationalCaseTransitionTarget target,
    String? summary,
    String? internalNote,
  }) async {
    state = const AdminOperationalCaseActionState(isLoading: true);
    try {
      return await ref.read(adminOperationalCaseRepositoryProvider).transitionCase(
            caseId: caseId,
            target: target,
            summary: summary,
            internalNote: internalNote,
          );
    } finally {
      state = const AdminOperationalCaseActionState(isLoading: false);
    }
  }

  Future<bool> resolveCase({
    required String caseId,
    required OperationalCaseResolutionTarget target,
    required String summary,
  }) async {
    state = const AdminOperationalCaseActionState(isLoading: true);
    try {
      return await ref.read(adminOperationalCaseRepositoryProvider).resolveCase(
            caseId: caseId,
            target: target,
            summary: summary,
          );
    } finally {
      state = const AdminOperationalCaseActionState(isLoading: false);
    }
  }

  Future<bool> escalateCase({
    required String caseId,
    required String targetAdminUserId,
    String? reason,
  }) async {
    state = const AdminOperationalCaseActionState(isLoading: true);
    try {
      return await ref.read(adminOperationalCaseRepositoryProvider).escalateCase(
            caseId: caseId,
            targetAdminUserId: targetAdminUserId,
            reason: reason,
          );
    } finally {
      state = const AdminOperationalCaseActionState(isLoading: false);
    }
  }
}

final adminOperationalCaseQueueProvider = AutoDisposeAsyncNotifierProvider<
    AdminOperationalCaseQueueController,
    AdminOperationalCaseQueueState>(
  AdminOperationalCaseQueueController.new,
);

final adminOperationalCaseActionProvider =
    AutoDisposeNotifierProvider<AdminOperationalCaseActionController, AdminOperationalCaseActionState>(
  AdminOperationalCaseActionController.new,
);

final adminOperationalCaseDetailProvider =
    FutureProvider.autoDispose.family<AdminOperationalCaseDetail?, String>((ref, caseId) async {
  return ref.watch(adminOperationalCaseRepositoryProvider).getOperationalCaseDetail(caseId);
});

final adminOperationalEscalationTargetsProvider =
    FutureProvider.autoDispose<List<AdminOperationalEscalationTarget>>((ref) async {
  return ref.watch(adminOperationalCaseRepositoryProvider).getEscalationTargets();
});
