import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_verification_repository.dart';

class AdminVerificationActionState {
  final bool isLoading;

  const AdminVerificationActionState({this.isLoading = false});
}

class AdminVerificationQueueState {
  final VerificationQueueQuery query;
  final bool isLoading;
  final List<VerificationQueueItem> items;
  final bool hasMore;
  final VerificationQueueCounts counts;

  const AdminVerificationQueueState({
    required this.query,
    required this.isLoading,
    required this.items,
    required this.hasMore,
    required this.counts,
  });

  factory AdminVerificationQueueState.initial() {
    return AdminVerificationQueueState(
      query: const VerificationQueueQuery(
        tab: VerificationQueueTab.suppliers,
        sort: VerificationQueueSort.slaUrgency,
        search: '',
      ),
      isLoading: false,
      items: const [],
      hasMore: false,
      counts: VerificationQueueCounts.empty(),
    );
  }

  AdminVerificationQueueState copyWith({
    VerificationQueueQuery? query,
    bool? isLoading,
    List<VerificationQueueItem>? items,
    bool? hasMore,
    VerificationQueueCounts? counts,
  }) {
    return AdminVerificationQueueState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      counts: counts ?? this.counts,
    );
  }
}

class AdminVerificationQueueController extends AutoDisposeAsyncNotifier<AdminVerificationQueueState> {
  @override
  Future<AdminVerificationQueueState> build() async {
    final query = AdminVerificationQueueState.initial().query;
    final page = await ref.read(adminVerificationRepositoryProvider).getVerificationQueue(query);
    return AdminVerificationQueueState.initial().copyWith(
      query: query,
      items: page.items,
      hasMore: page.hasMore,
      counts: page.counts,
    );
  }

  Future<void> updateSearch(String value) async {
    final current = state.value ?? AdminVerificationQueueState.initial();
    await _reload(current.query.copyWith(search: value, page: 0));
  }

  Future<void> updateTab(VerificationQueueTab tab) async {
    final current = state.value ?? AdminVerificationQueueState.initial();
    await _reload(current.query.copyWith(tab: tab, page: 0));
  }

  Future<void> updateSort(VerificationQueueSort sort) async {
    final current = state.value ?? AdminVerificationQueueState.initial();
    await _reload(current.query.copyWith(sort: sort, page: 0));
  }

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || current.isLoading || !current.hasMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoading: true));
    final nextQuery = current.query.copyWith(page: current.query.page + 1);
    try {
      final nextPage = await ref.read(adminVerificationRepositoryProvider).getVerificationQueue(nextQuery);
      state = AsyncData(
        current.copyWith(
          query: nextQuery,
          isLoading: false,
          items: [...current.items, ...nextPage.items],
          hasMore: nextPage.hasMore,
          counts: nextPage.counts,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    final current = state.value ?? AdminVerificationQueueState.initial();
    await _reload(current.query.copyWith(page: 0));
  }

  Future<void> _reload(VerificationQueueQuery query) async {
    final current = state.value ?? AdminVerificationQueueState.initial();
    state = AsyncData(current.copyWith(query: query, isLoading: true));
    try {
      final page = await ref.read(adminVerificationRepositoryProvider).getVerificationQueue(query);
      state = AsyncData(
        current.copyWith(
          query: query,
          isLoading: false,
          items: page.items,
          hasMore: page.hasMore,
          counts: page.counts,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

final adminVerificationQueueProvider = AutoDisposeAsyncNotifierProvider<
    AdminVerificationQueueController,
    AdminVerificationQueueState>(
  AdminVerificationQueueController.new,
);

final adminVerificationDetailProvider =
    FutureProvider.autoDispose.family<AdminVerificationDetail?, String>((ref, caseId) async {
  return ref.watch(adminVerificationRepositoryProvider).getVerificationDetail(caseId);
});

class AdminVerificationActionController extends AutoDisposeNotifier<AdminVerificationActionState> {
  @override
  AdminVerificationActionState build() => const AdminVerificationActionState();

  Future<bool> submitReviewDecision({
    required AdminVerificationDetail detail,
    required VerificationReviewDecision decision,
    String? reason,
    VerificationReviewFeedbackPayload? feedback,
  }) async {
    state = const AdminVerificationActionState(isLoading: true);
    final ok = await ref.read(adminVerificationRepositoryProvider).submitReviewDecision(
          detail: detail,
          decision: decision,
          reason: reason,
          feedback: feedback,
        );
    state = const AdminVerificationActionState(isLoading: false);
    return ok;
  }
}

final adminVerificationActionProvider =
    AutoDisposeNotifierProvider<AdminVerificationActionController, AdminVerificationActionState>(
  AdminVerificationActionController.new,
);
